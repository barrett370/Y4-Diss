using Distributions
using StatsBase
using Distributed
using MLStyle
include("GAUtils.jl")

function uniform_mutation!(P::Array{Individual})::Array{Individual}
    μ = 0.1
    for i in P[2:end] # Leave most fit individual alone TODO consider if this is desirable behaviour
        if length(i.phenotype.genotype) > 2
            if Distributions.sample([true, false], Weights([1 - μ, μ]))
                x_rng = sort([i.phenotype.source.x, i.phenotype.goal.x])
                y_rng = sort([i.phenotype.source.y, i.phenotype.goal.y])

                x_p0 = rand(Uniform(-10, x_rng[1])) #TODO work out better low value
                x_p1 = rand(Uniform(x_rng[1], x_rng[2]))
                x_p2 = rand(Uniform(x_rng[2], 2 * x_rng[2])) #TODO change 15 to road length once implemented
                x_r = Distributions.sample([x_p0, x_p1, x_p2], Weights([0.2, 0.6, 0.2]))

                y_p0 = rand(Uniform(-10, y_rng[1])) # TODO work out better low value
                y_p1 = rand(Uniform(y_rng[1], y_rng[2]))
                y_p2 = rand(Uniform(y_rng[2], 2 * y_rng[2]))
                y_r = Distributions.sample([y_p0, y_p1, y_p2], Weights([0.2, 0.6, 0.2]))

                i.phenotype.genotype[rand(2:(length(i.phenotype.genotype) - 1))] =
                    ControlPoint(x_r, y_r) # TODO Consider allowing mutation to go above or below start or end points
            end
        end
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
        o1 = append!(p1[1:i], p2[(i + 1):end])
        o2 = append!(p2[1:i], p1[(i + 1):end])

        append!(offspring, [Individual(Phenotype(start, o1 |> getGenotype, goal), 0)])
        append!(offspring, [Individual(Phenotype(start, o2 |> getGenotype, goal), 0)])
    end
    offspring
end


function selection(P::Array{Individual}; method="roulette")

    @match method begin
        "roulette" => return roulette_selection(P)
        "ranked" => return rank_selection(P)
        _ => return MissingException("Must be a valid selection function {roulette, ranked}")
    end


end


function roulette_selection(P::Array{Individual})::Array{Individual}
    n = length(P)
    new_pop::Array{Individual} = []
    Sum_𝓕 = reduce(+, map(p -> p.fitness, P))
    partial = rand(0:0.01:Sum_𝓕)
    sort!(P, by = p -> p.fitness)
    while length(new_pop) < n # Steady state population (for now) TODO review this
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

function rank_selection(P::Array{Individual}; ranking_function="linear")::Array{Individual}

    M = length(P)
    sort!(P, by = p -> p.fitness, rev=true)
    @match ranking_function begin
        "linear" => begin

            α = M/100 # TODO tweak α and β
            β = 2 - α
            (⋅) = (*)
            p(γ) = (α + (β - α) ⋅ (γ/(M-1))) / M
            new_P = []
            while length(new_P) < M

                for i in 1:M
                    pᵧ = p(i-1)
                    if Distributions.sample([true, false], Weights([pᵧ, 1 - pᵧ]))[1]
                        append!(new_P,[P[i]])
                    end
                end
            end

            return new_P
        end
        "exponential" => begin
            return MissingException("Not implemented")
        end
        "power" => begin
            return MissingException("Not implemented")
        end
        "geometric" => begin
            return MissingException("Not implemented")
        end
        _ => return MissingException("Must be a valid ranking function")
    end
end
