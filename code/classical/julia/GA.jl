include("GAUtils.jl")


function chord_length(curve::BezierCurve)
    first = curve[1]
    last = curve[end]
    √((first.x - last.x)^2 + (first.y - last.y)^2)
end

function polygon_length(curve::BezierCurve)
    l = 0
    for i = 1:length(ps)-1
        l += √((curve[i].x - curve[i+1].x)^2 + (curve[i].y - curve[i+1].y)^2)
    end
    l
end


function Fitness(i::Individual)
    α = 0
    β = 0
    n = length(i.phenotype.genotype)
    l =
        (
            2 * chord_length(i.phenotype.genotype) +
            (n - 1) * polygon_length(i.phenotype.genotype)
        ) / (n + 1)
    l1 = 0 # length of infeasible segment
    l2 = 0 # length of path in which min safe distance is broken
    l + α * l1 + β * l2
end

𝓕 = Fitness # function alias


function GA()
    # Initialise population
    n = 10 # Population size
    start = Point(0, 0)
    goal = Point(12, 5)

    boundary1(x) = sin(0.3 * x)
    boundary2(x) = sin(0.35 * x) + 4
    road = Road(boundary1, boundary2)

    P = generatePopulation(n, start, goal, road)

    while true # Replace with stopping criteria
        map(p -> p.fitness =  p |> 𝓕, P) # Calculate fitness for population
        # Selection

        # Genetic Operators
        ## Crossover
        ## Mutation
    end

end
