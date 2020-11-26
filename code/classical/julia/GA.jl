using Distributions
using StatsBase
include("GAUtils.jl")
include("plottingUtils.jl")



function chord_length(curve::BezierCurve)
    first = curve[1]
    last = curve[end]
    √((first.x - last.x)^2 + (first.y - last.y)^2)
end

function polygon_length(curve::BezierCurve)
    l = 0
    for i = 1:length(curve)-1
        l += √((curve[i].x - curve[i+1].x)^2 + (curve[i].y - curve[i+1].y)^2)
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
                cx -> round(cx, digits = 1) == round(x, digits = 1),
                obstacle_values[1],
            )
            for j in potential_circle_intersect_is
                if round(y, digits = 1) == round(obstacle_values[2][j], digits = 1)
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
    for i = 1:length(curve_values[1])
        if curve_values[2][i] >= road.boundary_2(curve_values[1][i]) || curve_values[2][i] <= road.boundary_1(curve_values[1][i])

            dist = √(
                (curve_values[1][i] - curve_values[1][i+1])^2 +
                (curve_values[2][i] - curve_values[2][i+1])^2,
            )
            # @show 100*dist
            l = l + 100 * dist
        end
    end
    l
end

function feasibilityCheck(road::Road, i::Individual)::Bool end

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
    l
end


function Fitness(r::Road, i::Individual)
    α = 15 # Infeasible path Penalty weight
    β = 1.6 # Min safe distance break penalty weight
    n = length(i.phenotype.genotype)
    l =
        (
            2 * chord_length(i.phenotype.genotype) +
            (n - 1) * polygon_length(i.phenotype.genotype)
        ) / (n + 1)
    l1 = infeasible_distance(r, i.phenotype.genotype)
    l2 = high_proximity_distance(r, i.phenotype.genotype) # length of path in which min safe distance is broken
    l + α * l1 + β * l2
end

function roulette_selection(P::Array{Individual})
    n = length(P)
    new_pop::Array{Individual} = []
    Sum_𝓕 = reduce(+, map(p -> p.fitness, P))
    partial = rand(0:0.01:Sum_𝓕)
    sort!(P, by = p -> p.fitness)
    while length(new_pop) < n # Steady state population (for now)
        for i in P
            if partial + i.fitness >= Sum_𝓕
                append!(new_pop, [i])
                partial = 0
            else
                partial = partial + i.fitness
            end
        end
    end
    new_pop
end

function simple_crossover(P::Array{Individual})
    n = length(P)
    start = P[1].phenotype.source
    goal = P[1].phenotype.goal
    offspring::Array{Individual} = []
    while n > 1
        p1_i = rand(1:n)
        p1 = P[p1_i]
        deleteat!(P, p1_i)
        n = n - 1
        p2_i = rand(1:n)
        p2 = P[p2_i]
        deleteat!(P, p2_i)
        n = n - 1

        p1 = p1 |> p -> p.phenotype.genotype |> getGenotypeString
        p2 = p2 |> p -> p.phenotype.genotype |> getGenotypeString
        n1, n2 = length(p1), length(p2)
        if n1 < n2
            i = rand(1:2:n1)
        else
            i = rand(1:2:n2)
        end
        o1 = append!(p1[1:i], p2[i+1:end])
        o2 = append!(p2[1:i], p1[i+1:end])

        append!(offspring, [Individual(Phenotype(start, [], o1 |> getGenotype, goal), 0)])
        append!(offspring, [Individual(Phenotype(start, [], o2 |> getGenotype, goal), 0)])
        # if length(filter(!isValid, offspring)) > 0
        #     debugIsValid(o1)
        #     debugIsValid(o2)
        #     @show p1, p2
        #     @show o1, o2
        # end
    end
    offspring
end

function debugIsValid(i::Individual)

    if sort(i.phenotype.genotype, by = g -> g.x) != i.phenotype.genotype
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

    sort(i.phenotype.genotype, by = g -> g.x) == i.phenotype.genotype &&
        length(i.phenotype.genotype) >= 2 &&
        i.phenotype.genotype[1] == i.phenotype.source &&
        i.phenotype.genotype[end] == i.phenotype.goal

end

function repair(i::Individual)::Individual
    sort!(i.phenotype.genotype, by = g -> g.x)
    return i
end

function uniform_mutation(P::Array{Individual})::Array{Individual}
    μ = 0.1
    # for i in P
    for i in P[2:end] # Leave most fit individual alone TODO consider if this is desirable behaviour
        if length(i.phenotype.genotype) > 2
            if sample([true, false], Weights([1 - μ, μ]))
                x_rng = sort([i.phenotype.source.x, i.phenotype.goal.x])
                y_rng = sort([i.phenotype.source.y, i.phenotype.goal.y])
                i.phenotype.genotype[rand(2:length(i.phenotype.genotype)-1)] = ControlPoint(
                    rand(Uniform(x_rng[1], x_rng[2])),
                    rand(Uniform(0, 2 * y_rng[2])),
                ) # TODO Consider allowing mutation to go above or below start or end points
            end
        end
        # if length(filter(!isValid, P)) > 0
        #     map(debugIsValid, P)
        # end
    end
    P
end


function GA(start::Point, goal::Point, road::Road, n_gens::Real=1, n::Real=10)
    # Initialise population
    if  start.y < road.boundary_1(start.x) || start.y > road.boundary_2(start.y) || goal.y < road.boundary_1(goal.x) || goal.y > road.boundary_2(goal.x)
        println("ERROR, start of goal is outside of roadspace")
        return
    end
    𝓕 = curry(Fitness,road)
    isFeasible = curry(feasibilityCheck,road)
    P = generatePopulation(n, start, goal, road)
    map(p -> p.fitness = p |> 𝓕, P) # Calculate fitness for initial population, map 𝓕 over all Individuals
    while true && n_gens > 0 && length(P) > 0# Replace with stopping criteria
        # Selection
        # savefig(plotGeneration!(draw_road(road,0,20),P,road,100,100-n_gens),string("./gifgen/gen-",100-n_gens))
        P = (P
            |> roulette_selection  # Selection operator
            |> simple_crossover # Crossover operator
            |> new_pop -> append!(P, new_pop)  # Add newly generated individuals to population
            |> uniform_mutation # apply mutation operator
            |> P -> begin map(p -> p.fitness = p |> 𝓕, P); P end # recalculate fitness of population after mutation
            |> P -> map(repair, P)  # repair infeasible solutions
            |> P -> sort(P, by=p -> p.fitness) # Sort my fitness
            |> P -> filter(isValid, P) # remove invalid solutions
            |> P -> P[1:n] # take top n
        )
        n_gens = n_gens - 1
    end
    savefig(plotGeneration!(draw_road(road,0,20),P,road,100),string("./gen-",n_gens))
    # P = filter(isFeasible,P)
    P
end
