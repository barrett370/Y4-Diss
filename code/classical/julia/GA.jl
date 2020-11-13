include("GAUtils.jl")


function chord_length(curve::BezierCurve)
    first = curve[1]
    last = curve[end]
    √((first.x - last.x)^2 + (first.y - last.y)^2)
end

function polygon_length(curve::BezierCurve)
    l = 0
    for i = 1:length(ps) - 1
        l += √((curve[i].x - curve[i + 1].x)^2 + (curve[i].y - curve[i + 1].y)^2)
    end
    l
end


function Fitness(i::Individual)
    α = 0 # Infeasible path Penalty weight
    β = 0 # Min safe distance break penalty weight
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


function GA(start::Point, goal::Point, road::Road, n::Real=10)
    # Initialise population 
    P = generatePopulation(n, start, goal, road)

    while true # Replace with stopping criteria
        map(p -> p.fitness = p |> 𝓕, P) # Calculate fitness for population, map 𝓕 over all Individuals
        # Selection

        # Genetic Operators
        ## Crossover
        ## Mutation
    end

end
