using DataStructures
using SharedArrays
using StaticArrays
using Distributed
include("bezier.jl")
include("roadNetwork.jl")
include("utils.jl")

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

function toSVector(i::Individual)::SVector{12,Float64}
    @show i
    real_array = getGenotypeString(i.phenotype.genotype)
    if length(real_array) < 12
        real_array = vcat(real_array,zeros(12-length(real_array)))
    end
    if length(real_array) > 12 # TODO why does this happen?
        real_array = real_array[1:12]
    end

    @show real_array
    return SVector{12}(map(r-> Float64(r), real_array))
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
        append!(ret, [ControlPoint(genotypeString[i], genotypeString[i + 1])])
    end
    ret
end

function getGenotype(svec::SVector{12,Float64})::BezierCurve
    ret::BezierCurve = []
    for i = 1:2:6
        append!(ret, [ControlPoint(svec[i], svec[i + 1])])
    end
    ret
end


MAX_P = 6


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
        n_control_points = rand(1:MAX_P)
        for i = 1:n_control_points
            new_x =
                ps[end].x +
                rand(x_distance / (n_control_points * 4):0.1:x_distance / n_control_points)
            if new_x > goal.x
                new_x = goal.x
            end
            new_y = ps[end].y + rand(-(y_distance / n):1 / n:(y_distance / n))
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

function chord_length(curve::BezierCurve)
    first = curve[1]
    last = curve[end]
    √((first.x - last.x)^2 + (first.y - last.y)^2)
end

function polygon_length(curve::BezierCurve)
    l = 0
    for i = 1:length(curve) - 1
        l += √((curve[i].x - curve[i + 1].x)^2 + (curve[i].y - curve[i + 1].y)^2)
    end
    l
end

function infeasible_distance(road::Road, curve::BezierCurve)
    l = 0
    curve_values = get_curve(curve)
    for obstacle in road.obstacles
        obstacle_values = []
        if typeof(obstacle) == Circle
            obstacle_values = get_circle(obstacle)
        elseif typeof(obstacle) == Rectangle
            # obstacle_values = get_rectangle(obstacle)
            obstacle_values = []
        end
        intersects = []
        for i = 1:length(curve_values[1])
            x = curve_values[1][i]
            y = curve_values[2][i]
            potential_circle_intersect_is = findall(
                cx -> round(cx, digits=1) == round(x, digits=1),
                obstacle_values[1],
            )
            for j in potential_circle_intersect_is
                if round(y, digits=1) == round(obstacle_values[2][j], digits=1)
                    append!(intersects, [(x, y)])
                end
            end
        end
        if length(intersects) > 0
            # @show string("Intersects for ", √(
            #         (intersects[1][1] - intersects[end][1])^2 +
            #         (intersects[1][2] - intersects[end][2])^2,
            #     ) )
            l =
                l + √(
                    (intersects[1][1] - intersects[end][1])^2 +
                    (intersects[1][2] - intersects[end][2])^2,
                ) # TODO replace with new bezier curve and find length of that, this is a cheap fix
        end
    end
    for i = 1:length(curve_values[1]) - 1
        if curve_values[2][i] >= road.boundary_2(curve_values[1][i]) ||
           curve_values[2][i] <= road.boundary_1(curve_values[1][i])

            dist = √(
                (curve_values[1][i] - curve_values[1][i + 1])^2 +
                (curve_values[2][i] - curve_values[2][i + 1])^2,
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
            for i = 1:length(curve_values[1]) - 1
                # @show   √((curve_values[1][i] - obstacle.centre.x)^2 +
                # (curve_values[2][i] - obstacle.centre.y)^2)
                if √(
                    (curve_values[1][i] - obstacle.centre.x)^2 +
                    (curve_values[2][i] - obstacle.centre.y)^2,
                ) <= threshold
                    l += √(
                        (curve_values[1][i + 1] - curve_values[1][i])^2 +
                        (curve_values[2][i + 1] - curve_values[2][i])^2,
                    )
                end
            end
        end
    end
    for i in length(curve_values[1]) - 1
        threshold = 0.6
        if abs(curve_values[2][i] - road.boundary_2(curve_values[1][i])) <= threshold ||
           abs(curve_values[2][i] - road.boundary_1(curve_values[1][i])) <= threshold

            dist = √(
                (curve_values[1][i] - curve_values[1][i + 1])^2 +
                (curve_values[2][i] - curve_values[2][i + 1])^2,
            )
            # @show 100*dist
            l = l + dist
        end
    end
    l
end

function bezLength(c::BezierCurve)::Real
    n = length(c)
    l =
        (
            2 * chord_length(c) +
            (n - 1) * polygon_length(c)
        ) / (n + 1)
    return l
end

function Fitness(r::Road, i::Individual)

    # Curve Fitness

    α = 8 # Infeasible path Penalty weight
    β = 2.5 # Min safe distance break penalty weight
    l = bezLength(i.phenotype.genotype)
    l1 = infeasible_distance(r, i.phenotype.genotype)
    l2 = high_proximity_distance(r, i.phenotype.genotype) # length of path in which min safe distance is broken


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
            if collisionDetection(i, o)
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
        if o != SVector{12,Float64}(zeros(12))
            println("Testing fitness of $i, wrt. $o, parallel")
            if collisionDetection(i.phenotype.genotype, o |> getGenotype)
                println("Detected collision!")
                base_fitness = base_fitness * 5 # TODO tune this
            end
        end
    end

    return base_fitness
end

function debugIsValid(i::Individual)

    if sort(i.phenotype.genotype, by=g -> g.x) != i.phenotype.genotype
        println("control points not in order")
    elseif length(i.phenotype.genotype) < 2
        println("too few control points")
    elseif i.phenotype.genotype[1] != i.phenotype.source
        println("initial control point is not origin")
    elseif i.phenotype.genotype[end] != i.phenotype.goal
        println("final control point is not goal")
    end
end

function isValid(i::Individual)::Bool

    sort(i.phenotype.genotype, by=g -> g.x) == i.phenotype.genotype &&
        length(i.phenotype.genotype) >= 2 &&
        i.phenotype.genotype[1] == i.phenotype.source &&
        i.phenotype.genotype[end] == i.phenotype.goal

end

function repair(i::Individual)::Individual
    sort!(i.phenotype.genotype, by=g -> g.x)
    return i
end

function collisionDetection(c1::BezierCurve, c2::BezierCurve)::Bool
    @show "Detecting Collisions parallel"
    (b, ps) = bezInt(c1, c2)
    if b # if they do intersect
        println("Intersection")
        c1_to_intersect = deepcopy(c1)
        for i in 1:length(c1)
            if c1[i].x > ps[1][1].x # TODO tweak this
                c1_to_intersect = c1_to_intersect[1:i]
                append!(c1_to_intersect, ps[1][2:end])
                break
            end
        end

        c2_to_intersect = deepcopy(c2)
        for i in 1:length(c2) # for each control point
            if c2[i].x > ps[2][1].x # TODO tweak this | if the x position of the control point is greater than the x value of the inital point in the section of the curve that insersects
                c2_to_intersect = c2_to_intersect[1:i] # restrict the intersection to this section of c2
                append!(c2_to_intersect, ps[2][2:end]) # append the rest of the intersected section creating a curve that goes from c2 start to end of intersection section
                break
            end
        end
        @show abs(bezLength(c1_to_intersect) - bezLength(c2_to_intersect)) < 3.5
        return abs(bezLength(c1_to_intersect) - bezLength(c2_to_intersect)) < 3.5 # TODO tweak pessimistic fuzz to this comparison
        # If the distance between (c1 origin -> end of c1 intersection section) -  distance between (c2 origin -> end of c2 intersection section)
        # is less than <val>, we say they reached approx the same point at approx the same time => collision!
    else
        return false
    end

end


function collisionDetection(i1::Individual, i2::Individual)::Bool

    println("Detecting Collisions")

    (b, ps) = bezInt(i1.phenotype.genotype, i2.phenotype.genotype)
    if b # if they do intersect
        println("Intersection")
        i1_to_intersect = i1.phenotype.genotype
        for i in 1:length(i1.phenotype.genotype)
            if i1.phenotype.genotype[i].x > ps[1][1].x # TODO tweak this
                i1_to_intersect = i1_to_intersect[1:i]
                append!(i1_to_intersect, ps[1][2:end])
                break
            end
        end

        i2_to_intersect = i2.phenotype.genotype
        for i in 1:length(i2.phenotype.genotype)
            if i2.phenotype.genotype[i].x > ps[2][1].x # TODO tweak this
                i2_to_intersect = i2_to_intersect[1:i]
                append!(i2_to_intersect, ps[2][2:end])
                break
            end
        end
        @show abs(bezLength(i1_to_intersect) - bezLength(i2_to_intersect))
        return abs(bezLength(i1_to_intersect) - bezLength(i2_to_intersect)) < 4 # TODO tweak pessimistic fuzz to this comparison
    else
        return false
    end
end

function get_curve(c::BezierCurve, n=500)
    ps_x, ps_y = [], []
    for x in range(0, 1, step=1 / n)
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
