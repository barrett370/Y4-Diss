using Distributions
using StatsBase
using Distributed
using MLStyle
include("GAUtils.jl")

function mutation!(
    P::Array{Individual},
    road::Road;
    method::MutationMethod,
)::Array{Individual}
    if method == uniform
        return uniform_mutation!(P)

    elseif method == gaussian


        return gaussian_mutation!(P, road)
    end


end

function crossover(P::Array{Individual}; method)::Array{Individual}
    if method == simple 
        return simple_crossover(P)
    elseif method == k_point 
        return k_point_crossover(P)
    end
end


function uniform_mutation!(P::Array{Individual})::Array{Individual}
    μ = 0.1
    for i in P[2:end] # Leave most fit individual alone TODO consider if this is desirable behaviour
        if length(i.phenotype.genotype) > 2
            if Distributions.sample([true, false], Weights([1 - μ, μ]))
                x_rng = sort([i.phenotype.source.x, i.phenotype.goal.x])
                y_rng = sort([i.phenotype.source.y, i.phenotype.goal.y])

                x_p0 = rand(Uniform(-10, x_rng[1])) # TODO work out better low value
                x_p1 = rand(Uniform(x_rng[1], x_rng[2]))
                x_p2 = rand(Uniform(x_rng[2], 2 * x_rng[2])) # TODO change 15 to road length once implemented
                x_r = Distributions.sample(
                    [x_p0, x_p1, x_p2],
                    Weights([0.2, 0.6, 0.2]),
                )

                y_p0 = rand(Uniform(-10, y_rng[1])) # TODO work out better low value
                sorted_rng = sort([y_rng[1], y_rng[2]])
                if sorted_rng[1] == sorted_rng[2]
                    # TODO make this not be a plaster
                    y_p1 = sorted_rng[1]
                else
                    y_p1 = rand(Uniform(sorted_rng[1], sorted_rng[2]))
                end

                y_p2 = rand(Uniform(sorted_rng[2], 2 * sorted_rng[2]))
                y_r = Distributions.sample(
                    [y_p0, y_p1, y_p2],
                    Weights([0.2, 0.6, 0.2]),
                )

                i.phenotype.genotype[rand(2:(length(i.phenotype.genotype) - 1))] =
                    ControlPoint(x_r, y_r) # TODO Consider allowing mutation to go above or below start or end points
            end
        end
    end
    P
end

function gaussian_mutation!(P::Array{Individual}, road::Road)::Array{Individual}
    # Interval bounds
    μ = 0.5 # TODO tweak probability of selecting individual
    for i in P
        if Distributions.sample([true, false], Weights([μ, 1 - μ])) # Do we mutate this candidate ?
            new_i = deepcopy(i)
            if i.phenotype.genotype |> length < 3
                break
            end
            c_index = rand(2:length(new_i.phenotype.genotype) - 1)
            cᵢ = new_i.phenotype.genotype[c_index] # randomly selected gene
            x_bound = sort([new_i.phenotype.source.x, new_i.phenotype.goal.x])
            y_bound = [
                -(
                    (
                        road.boundary_1(x_bound[1]) +
                        road.boundary_1(x_bound[2])
                    ) / 2
                ) * 2, # TODO tweak, y can be from the average y of the road bottom *1.5 to :
                (
                    (
                        road.boundary_2(x_bound[1]) +
                        road.boundary_2(x_bound[2])
                    ) / 2
                ) * 2, # TODO tweak, average yo fo road top * 1.5
            ]




            # standard deviation
            σᵢ_x = 0.4 * abs(x_bound[1] - x_bound[2])# TODO make sure this is correct
            σᵢ_y = 0.4 * abs(y_bound[1] - y_bound[2])# TODO make sure this is correct

            cᵢ′ = Point(
                min(
                    max(rand(Distributions.Gaussian(cᵢ.x, σᵢ_x)), x_bound[1]),
                    x_bound[2],
                ),
                min(
                    max(rand(Distributions.Gaussian(cᵢ.y, σᵢ_y)), y_bound[1]),
                    y_bound[2],
                ),
            )


            # @show cᵢ′ == cᵢ
            new_i.phenotype.genotype[c_index] = cᵢ′
            append!(P, [new_i])

        end
    end
    P
end

function k_point_crossover(P::Array{Individual})::Array{Individual}
    n = P |> length
    start = P[1].phenotype.source
    goal = P[1].phenotype.goal
    offspring::Array{Individual} = []
    P_copy = deepcopy(P)
    while n >= 2
        p1_i = rand(1:n) # randomly select parent 1
        p1 = P_copy[p1_i]
        deleteat!(P_copy, p1_i)
        n -= 1
        p2_i = rand(1:n)# randomly select parent 2
        p2 = P_copy[p2_i]
        deleteat!(P_copy, p2_i)
        n -= 1
        p1 = p1 |> p -> p.phenotype.genotype |> getGenotypeString
        p2 = p2 |> p -> p.phenotype.genotype |> getGenotypeString
        n1, n2 = length(p1), length(p2)
        if n1 > 6 && n2 > 6


            k = rand(1:Int64(ceil(min(n1, n2) / 2)))

            p1, p2
            is = vcat(3:2:min(n1, n2) - 2)

            ks = rand(is, k) |> sort |> unique
            o1::Array{Real} = p1[1:ks[1] - 1]
            o2::Array{Real} = p2[1:ks[1] - 1]
            switch = true
            for i in 2:(ks |> length) - 1
                if switch
                    ks[i], ks[i + 1] 
                    append!(o1, p2[ks[i]:ks[i + 1] - 1])
                    append!(o2, p1[ks[i]:ks[i + 1] - 1])
                    switch = false
                else
                    append!(o1, p1[ks[i]:ks[i + 1] - 1])
                    append!(o2, p2[ks[i]:ks[i + 1] - 1])
                    switch = true
                end
            

                    

            end



            append!(
                offspring,
                [Individual(Phenotype(start, append!(o1 |> getGenotype, [goal]), goal), 0)],
            )
            append!(
                offspring,
                [Individual(Phenotype(start, append!(o2 |> getGenotype, [goal]), goal), 0)],
            )

        end
    end
    offspring
end

function simple_crossover(P::Array{Individual})::Array{Individual}
    n = length(P)
    start = P[1].phenotype.source
    goal = P[1].phenotype.goal
    offspring::Array{Individual} = []
    P_copy = deepcopy(P)
    while n > 1
        p1_i = rand(1:n) # randomly select parent 1
        p1 = P_copy[p1_i]
        deleteat!(P_copy, p1_i)
        n = n - 1
        p2_i = rand(1:n)# randomly select parent 2
        p2 = P_copy[p2_i]
        deleteat!(P_copy, p2_i)
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

        append!(
            offspring,
            [Individual(Phenotype(start, o1 |> getGenotype, goal), 0)],
        )
        append!(
            offspring,
            [Individual(Phenotype(start, o2 |> getGenotype, goal), 0)],
        )
    end
    offspring
end


function selection(
    P::Array{Individual};
    method::SelectionMethod=roulette,
)::Array{Individual}

    # @match method begin
    #    roulette => return roulette_selection(P)
    #    ranked => return rank_selection(P)
    #    _ => return MissingException(
    #        "Must be a valid selection function {roulette, ranked}",
    #    )
    # end

    if method == roulette
        return roulette_selection(P)
    elseif method == ranked
        return rank_selection(P)
    end


end


function roulette_selection(P::Array{Individual})::Array{Individual}
    n = length(P)
    new_pop::Array{Individual} = []
    Sum_𝓕 = reduce(+, map(p -> p.fitness, P))
    partial = rand(0:0.01:Sum_𝓕)
    sort!(P, by=p -> p.fitness)
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

function rank_selection(
    P::Array{Individual};
    ranking_function="linear",
)::Array{Individual}

    M = length(P)
    sort!(P, by=p -> p.fitness, rev=true)
    @match ranking_function begin
        "linear" => begin

            α = M / 100 # TODO tweak α and β
            β = 2 - α
            (⋅) = (*)
            p(γ) = (α + (β - α) ⋅ (γ / (M - 1))) / M
            new_P = []
            while length(new_P) < M

        for i = 1:M
            pᵧ = p(i - 1)
            if Distributions.sample(
                        [true, false],
                        Weights([pᵧ, 1 - pᵧ]),
                    )[1]
                append!(new_P, [P[i]])
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
