include("GAUtils.jl")
include("geneticOperators.jl")


function CGA(
    starts::Array{Point},
    goals::Array{Point},
    road::Road;
    n_gens::Real=1,
    n::Real=10,
    selection_method="roulette"
)::Array{Individual}

    completed_plans::Array{Individual} = []
    ret::Array{Individual} = []
    for (start, goal) in zip(starts, goals)
        @show start, goal
        P = CGA(start, goal, road, completed_plans, n_gens=n_gens, n=n, selection_method=selection_method)
        append!(completed_plans, [P[1]])
        # append!(ret,[P[1]])
    end

    completed_plans
    # ret

end

function CGA(start::Point, goal::Point, road::Road, other_routes::Array{Individual}; n_gens::Real=1, n::Real=10, selection_method="roulette")::Array{Individual}
    # Initialise population
    if start.y < road.boundary_1(start.x) || start.y > road.boundary_2(start.y) || goal.y < road.boundary_1(goal.x) || goal.y > road.boundary_2(goal.x)
        println("ERROR, start of goal is outside of roadspace")
        return []
    end
    𝓕 = curry(curry(Fitness, road), other_routes) # Curry fitness function with road as this is a static attribute of the function. Allows for nicer piping of data.
    P = generatePopulation(n, start, goal, road)
    map(p -> p.fitness = p |> 𝓕, P) # Calculate fitness for initial population, map 𝓕 over all Individuals
    while true && n_gens > 0 && length(P) > 0# Replace with stopping criteria
        # savefig(plotGeneration!(draw_road(road,0,20),P,road,100,100-n_gens),string("./gifgen/gen-",100-n_gens))
        P = (P
            |> P -> selection(P, method=selection_method)  # Selection operator
            |> simple_crossover |> new_pop -> append!(P, new_pop)  ## Crossover operator & Add newly generated individuals to population
            |> uniform_mutation! # apply mutation operator
            |> P -> begin map(p -> p.fitness = p |> 𝓕, P); P end # recalculate fitness of population after mutation
            |> P -> map(repair, P)  # attempt repair of invalid solutions
            |> P -> sort(P, by=p -> p.fitness) # Sort my fitness
            |> P -> filter(isValid, P) # remove invalid solutions
            |> P -> P[1:minimum([n,length(P)])]# take top n
        )
        n_gens = n_gens - 1
    end
#    savefig(plotGeneration!(draw_road(road,0,20),P,road,100),string("./gen-",n_gens))
    # P = filter(i->high_proximity_distance(road,i.phenotype.genotype)==0,filter(i -> infeasible_distance(road,i.phenotype.genotype)==0,P))
    P
end

function GA(start::Point, goal::Point, road::Road; n_gens::Real=1, n::Real=10, selection_method="roulette")::Array{Individual}
    # Initialise population
    if start.y < road.boundary_1(start.x) || start.y > road.boundary_2(start.y) || goal.y < road.boundary_1(goal.x) || goal.y > road.boundary_2(goal.x)
        println("ERROR, start of goal is outside of roadspace")
        return []
    end
    𝓕 = curry(Fitness, road) # Curry fitness function with road as this is a static attribute of the function. Allows for nicer piping of data.
    P = generatePopulation(n, start, goal, road)
    map(p -> p.fitness = p |> 𝓕, P) # Calculate fitness for initial population, map 𝓕 over all Individuals
    while true && n_gens > 0 && length(P) > 0# Replace with stopping criteria
        # savefig(plotGeneration!(draw_road(road,0,20),P,road,100,100-n_gens),string("./gifgen/gen-",100-n_gens))
        P = (P
            |> P -> selection(P, method=selection_method)  # Selection operator
            |> simple_crossover # Crossover operator
            |> new_pop -> append!(P, new_pop)  # Add newly generated individuals to population
            |> P -> gaussian_mutation!(P,road) # apply mutation operator
            |> P -> begin map(p -> p.fitness = p |> 𝓕, P); P end # recalculate fitness of population after mutation
            |> P -> map(repair, P)  # attempt repair of invalid solutions
            |> P -> sort(P, by=p -> p.fitness) # Sort my fitness
            |> P -> filter(isValid, P) # remove invalid solutions
            |> P -> P[1:(min(n, length(P)))] # take top n
        )
        n_gens = n_gens - 1
    end
#    savefig(plotGeneration!(draw_road(road,0,20),P,road,100),string("./gen-",n_gens))
    # P = filter(i->high_proximity_distance(road,i.phenotype.genotype)==0,filter(i -> infeasible_distance(road,i.phenotype.genotype)==0,P))
    P
end
