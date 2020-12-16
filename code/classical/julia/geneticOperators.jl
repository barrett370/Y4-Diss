using Distributions
using StatsBase

function uniform_mutation!(P::Array{Individual})::Array{Individual}
    μ = 1.1
    # for i in P
    for i in P[2:end] # Leave most fit individual alone TODO consider if this is desirable behaviour
        if length(i.phenotype.genotype) > 2
            if Distributions.sample([true, false], Weights([1 - μ, μ]))
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

        append!(offspring, [Individual(Phenotype(start, o1 |> getGenotype, goal), 0)])
        append!(offspring, [Individual(Phenotype(start, o2 |> getGenotype, goal), 0)])
        # if length(filter(!isValid, offspring)) > 0
        #     debugIsValid(o1)
        #     debugIsValid(o2)
        #     @show p1, p2
        #     @show o1, o2
        # end
    end
    offspring
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
