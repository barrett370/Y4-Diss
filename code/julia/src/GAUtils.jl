using DataStructures
using SharedArrays
using StaticArrays
using Distributed
include("bezier.jl")
include("roadNetwork.jl")
include("utils.jl")
include("ftbezier.jl")


mutable struct Genotype
    curve::BezierCurve
    # velocityProfile::Dict{Real,Real}
end

mutable struct Phenotype
    source::Point
    genotype::BezierCurve
    goal::Point
end
mutable struct Individual
    phenotype::Phenotype
    fitness::Real
end

@enum SelectionMethod begin
    roulette
    ranked
end

@enum MutationMethod begin
    uniform
    gaussian
end

MAX_P = 10

function toSVector(i::Individual)::SVector{2 * MAX_P,Float64}
    @debug i
    real_array = getGenotypeString(i.phenotype.genotype)
    if length(real_array) < 2 * MAX_P
        real_array = vcat(real_array, zeros(2 * MAX_P - length(real_array)))
    end
    if length(real_array) > 2 * MAX_P# TODO why does this happen?
        @warn "too many control points? $i"
        real_array = real_array[1:2*MAX_P]
    end

    @debug real_array
    return SVector{2 * MAX_P}(map(r -> Float64(r), real_array))
end



function getGenotypeString(genotype::BezierCurve)::Array{Real}
    genotype_str = []
    for point in genotype
        append!(genotype_str, point.x)
        append!(genotype_str, point.y)
    end
    genotype_str
end

function getGenotype(genotypeString::Array{Real})::BezierCurve
    ret::BezierCurve = []
    for i = 1:2:length(genotypeString)
        append!(ret, [ControlPoint(genotypeString[i], genotypeString[i+1])])
    end
    ret
end

function getGenotype(svec::SVector{2 * MAX_P,Float64})::BezierCurve
    ret::BezierCurve = []
    for i = 1:2:(svec|> length)
        append!(ret, [ControlPoint(svec[i], svec[i+1])])
    end
    ret
end


MAX_P = 10


function generatePopulation(
    n::Integer,
    start::Point,
    goal::Point,
    r::Road,
)::Array{Individual}
    x_distance = abs(start.x - goal.x)
    y_distance = abs(start.y - goal.y)
    P = []
    for i = 1:n
        ps = [start]
        n_control_points = rand(0:MAX_P)
        for i = 1:n_control_points
            new_x =
                ps[end].x + rand(
                    x_distance/(n_control_points*4):0.1:x_distance/n_control_points,
                )
            if new_x > goal.x
                new_x = goal.x
            end
            new_y = ps[end].y + rand(-2*(y_distance/n):1/n:2*(y_distance/n))
            if new_y > goal.y
                new_y = goal.y
            end

            append!(ps, [ControlPoint(new_x, new_y)])
            if new_x >= goal.x && new_y >= goal.y
                break
            end
        end
        append!(ps, [goal])
        append!(P, [Individual(Phenotype(start, BezierCurve(ps), goal), 0)])
    end
    P
end

function infeasible_distance(road::Road, curve::BezierCurve)
    l = 0
    curve_values = get_curve(curve)
    for obstacle in road.obstacles
        intersects = []
        if typeof(obstacle) == Circle
            obstacle_values = get_circle(obstacle)
            for i = 1:length(curve_values[1])
                x = curve_values[1][i]
                y = curve_values[2][i]
                potential_circle_intersect_is = findall(
                    cx -> round(cx, digits = 1) == round(x, digits = 1),
                    obstacle_values[1],
                )
                for j in potential_circle_intersect_is
                    if round(y, digits = 1) ==
                       round(obstacle_values[2][j], digits = 1)
                        t = i / 500
                        append!(intersects, [(x, y, t)])
                    end
                end
            end
        elseif typeof(obstacle) == Rectangle
            # obstacle_values = get_rectangle(obstacle)
            for i = 1:length(curve_values[1])
                x = curve_values[1][i]
                y = curve_values[2][i]

                if (
                    x > obstacle.origin.x && x < obstacle.origin.x + obstacle.w
                ) &&
                   (y > obstacle.origin.y && y < obstacle.origin.y + obstacle.h) # TODO assumes I define rectangles with origin at bottom left and always have positive h and w
                    t = i / 500
                    append!(intersects, [(x, y, t)])
                end
            end

        end
        if length(intersects) > 0
            pre_ob = deCasteljau(curve, intersects[1][3])[1]|> bezLength
            post_ob = curve_section = deCasteljau(
                deCasteljau(curve, intersects[1][3])[2],
                intersects[end][3],
            )[1] |> bezLength
            l += bezLength(b1) - pre_ob - post_ob
        end
    end
    for i = 1:length(curve_values[1])-1
        if curve_values[2][i] >= road.boundary_2(curve_values[1][i]) ||
           curve_values[2][i] <= road.boundary_1(curve_values[1][i])

            dist = √(
                (curve_values[1][i] - curve_values[1][i+1])^2 +
                (curve_values[2][i] - curve_values[2][i+1])^2,
            )
            # @show 100*dist
            l = l + dist
        end
    end
    l
end


function high_proximity_distance(road::Road, curve::BezierCurve)
    # work out of curve passes too close to obsitcles
    l = 0
    curve_values = get_curve(curve, 100) # TODO tweak n value for granularity
    for obstacle in road.obstacles
        if typeof(obstacle) == Circle
            threshold = obstacle.r * 1.5
            for i = 1:length(curve_values[1])-1
                # @show   √((curve_values[1][i] - obstacle.centre.x)^2 +
                # (curve_values[2][i] - obstacle.centre.y)^2)
                if √(
                    (curve_values[1][i] - obstacle.centre.x)^2 +
                    (curve_values[2][i] - obstacle.centre.y)^2,
                ) <= threshold
                    l += √(
                        (curve_values[1][i+1] - curve_values[1][i])^2 +
                        (curve_values[2][i+1] - curve_values[2][i])^2,
                    )
                end
            end
        end
    end
    for i in length(curve_values[1]) - 1
        threshold = 0.6
        if abs(curve_values[2][i] - road.boundary_2(curve_values[1][i])) <=
           threshold ||
           abs(curve_values[2][i] - road.boundary_1(curve_values[1][i])) <=
           threshold

            dist = √(
                (curve_values[1][i] - curve_values[1][i+1])^2 +
                (curve_values[2][i] - curve_values[2][i+1])^2,
            )
            # @show 100*dist
            l = l + dist
        end
    end
    l
end

function Fitness(r::Road, i::Individual)

    # Curve Fitness

    α = 20# Infeasible path Penalty weight
    β = 5 # Min safe distance break penalty weight
    l = bezLength(i.phenotype.genotype)
    l1 = infeasible_distance(r, i.phenotype.genotype)
    l2 = high_proximity_distance(r, i.phenotype.genotype) # length of path in which min safe distance is broken


    #@show l + α * l1 + β * l2
    l + α * l1 + β * l2
end

function Fitness(r::Road, os::Array{Individual}, i::Individual) # Given knowledge of other individuals in the roadspace penalise intersections

    cd = true# for testing, collision detection flag
    base_fitness = Fitness(r, i)

    for o in os
        # println("Testing fitness of $i, wrt. $o")
        # if bezInt(i.phenotype.genotype, o.phenotype.genotype)
        #    base_fitness = base_fitness * 5
        # end
        if cd # If collision detection is enabled (true by default)
            if ft_collisionDetection(i, o)
                println("Detected collision!")
                base_fitness = base_fitness * 5
            end
        end

    end
    return base_fitness
end

function Fitness(r::Road, os::SharedArray, i::Individual) # Given knowledge of other individuals in the roadspace penalise intersections

    base_fitness = Fitness(r, i)
    # if bezInt(i.phenotype.genotype, o.phenotype.genotype)
    #    base_fitness = base_fitness * 5
    #
    for o in os
        if o != SVector{2 * MAX_P,Float64}(zeros(o |> length))
            @debug "Testing fitness of $i, wrt. $o, parallel"
            if !MT
                if ft_collisionDetection(i.phenotype.genotype, o |> getGenotype)
                    @debug "Detected collision!"
                    base_fitness = base_fitness * 5 # TODO tune this
                end
            else
                if collisionDetection(i.phenotype.genotype, o |> getGenotype)
                    @debug "Detected collision!"
                    base_fitness = base_fitness * 5 # TODO tune this
                end
            end
        end
    end

    return base_fitness
end

function debugIsValid(i::Individual)

    if sort(i.phenotype.genotype, by = g -> g.x) != i.phenotype.genotype
        @debug "control points not in order"
    elseif length(i.phenotype.genotype) < 2
        @debug "too few control points"
    elseif i.phenotype.genotype[1] != i.phenotype.source
        @debug "initial control point is not origin"
    elseif i.phenotype.genotype[end] != i.phenotype.goal
        @debug "final control point is not goal"
    end
end

function isValid(i::Individual)::Bool

    sort(i.phenotype.genotype, by = g -> g.x) == i.phenotype.genotype &&
        length(i.phenotype.genotype) >= 2 &&
        i.phenotype.genotype[1] == i.phenotype.source &&
        i.phenotype.genotype[end] == i.phenotype.goal

end

function repair(i::Individual)::Individual
    sort!(i.phenotype.genotype, by = g -> g.x)
    return i
end
function ft_collisionDetection(c1::BezierCurve, c2::BezierCurve)::Bool
    @warn "Using fortran bezier lib"
    @show (b, ps) = ft_bezInt(c1,c2)
    if b
        if (deCasteljau(c1,ps[1])[1] |> bezLength) - (deCasteljau(c2,ps[2])[1] |> bezLength) < 0.5
            return true
        else
            return false
        end

    else
        return false
    end

end
function collisionDetection(c1::BezierCurve, c2::BezierCurve)::Bool
    (b, ps) = bezInt(c1, c2)
    @debug (b, ps)
    if b # if they do intersect
        @debug "Intersection"
        c1_to_intersect = deepcopy(c1)
        for i = 1:length(c1)
            if c1[i].x > ps[1][1].x # TODO tweak this
                c1_to_intersect = c1_to_intersect[1:i]
                append!(c1_to_intersect, ps[1][2:end])
                break
            end
        end

        c2_to_intersect = deepcopy(c2)
        for i = 1:length(c2) # for each control point
            if c2[i].x > ps[2][1].x # TODO tweak this | if the x position of the control point is greater than the x value of the inital point in the section of the curve that insersects
                c2_to_intersect = c2_to_intersect[1:i] # restrict the intersection to this section of c2
                append!(c2_to_intersect, ps[2][2:end]) # append the rest of the intersected section creating a curve that goes from c2 start to end of intersection section
                break
            end
        end
        return abs(bezLength(c1_to_intersect) - bezLength(c2_to_intersect)) <
               0.7 # TODO tweak pessimistic fuzz to this comparison
    # If the distance between (c1 origin -> end of c1 intersection section) -  distance between (c2 origin -> end of c2 intersection section)
    # is less than <val>, we say they reached approx the same point at approx the same time => collision!
    else
        return false
    end

end


#function collisionDetection(i1::Individual, i2::Individual)::Bool
#
#    @debug "Detecting Collisions"
#
#    (b, ps) = bezInt(i1.phenotype.genotype, i2.phenotype.genotype)
#    if b # if they do intersect
#        @debug "Intersection"
#        i1_to_intersect = i1.phenotype.genotype
#        for i = 1:length(i1.phenotype.genotype)
#            if i1.phenotype.genotype[i].x > ps[1][1].x # TODO tweak this
#                i1_to_intersect = i1_to_intersect[1:i]
#                append!(i1_to_intersect, ps[1][2:end])
#                break
#            end
#        end
#
#        i2_to_intersect = i2.phenotype.genotype
#        for i = 1:length(i2.phenotype.genotype)
#            if i2.phenotype.genotype[i].x > ps[2][1].x # TODO tweak this
#                i2_to_intersect = i2_to_intersect[1:i]
#                append!(i2_to_intersect, ps[2][2:end])
#                break
#            end
#        end
#        @debug abs(bezLength(i1_to_intersect) - bezLength(i2_to_intersect))
#        return abs(bezLength(i1_to_intersect) - bezLength(i2_to_intersect)) <
#               1.5 # TODO tweak pessimistic fuzz to this comparison
#    else
#        return false
#    end
#end

function get_curve(c::BezierCurve, n = 500)
    ps_x, ps_y = [], []
    for x in range(0, 1, step = 1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    ps_x, ps_y
end

function get_circle(c::Circle)
    ps_x, ps_y = [], []
    for t ∈ LinRange(0, 2π, 500)
        C = c(t)
        append!(ps_x, C[1])
        append!(ps_y, C[2])
    end
    ps_x, ps_y
end
