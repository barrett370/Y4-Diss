include("GAUtils.jl")


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


function roulette_selection(P::Array{Individual})
    n = length(P)
    new_pop::Array{Individual}  = []
    Sum_𝓕 = reduce(+, map(p -> p.fitness, P))
    partial = rand(0:0.01:Sum_𝓕)
    sort!(P, by=p -> p.fitness)
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
        i = rand(1:2:length(p1))
        o1 = append!(p1[1:i], p2[i + 1,end])
        o2 = append!(p2[1:i], p1[i + 1,end])
        
        append!(offspring, [Individual(Phenotype(start, [], o1 |> getGenotype, goal), 0)])
        append!(offspring, [Individual(Phenotype(start, [], o2 |> getGenotype, goal), 0)])
    end
    map(p -> p.fitness = p |> 𝓕, offspring) # Calculate fitness for new offspring
    offspring
end


function GA(start::Point, goal::Point, road::Road, n_gens::Real=1, n::Real=10)
    # Initialise population 
    @show P = generatePopulation(n, start, goal, road)

    while true && n_gens > 0 # Replace with stopping criteria
        map(p -> p.fitness = p |> 𝓕, P) # Calculate fitness for population, map 𝓕 over all Individuals
        # Selection
        new_pop = P |> roulette_selection
        # Genetic Operators
        ## Crossover
        @show offspring = new_pop |> simple_crossover

        

        ## Mutation

        n_gens = n_gens - 1 
    end

end
