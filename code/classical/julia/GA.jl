include("GAUtils.jl")
include("geneticOperators.jl")

function GA(start::Point, goal::Point, road::Road, n_gens::Real=1, n::Real=10)
    # Initialise population
    if  start.y < road.boundary_1(start.x) || start.y > road.boundary_2(start.y) || goal.y < road.boundary_1(goal.x) || goal.y > road.boundary_2(goal.x)
        println("ERROR, start of goal is outside of roadspace")
        return
    end
    𝓕 = curry(Fitness,road)
    P = generatePopulation(n, start, goal, road)
    map(p -> p.fitness = p |> 𝓕, P) # Calculate fitness for initial population, map 𝓕 over all Individuals
    while true && n_gens > 0 && length(P) > 0# Replace with stopping criteria
        # Selection
        # savefig(plotGeneration!(draw_road(road,0,20),P,road,100,100-n_gens),string("./gifgen/gen-",100-n_gens))
        P = (P
            |> roulette_selection  # Selection operator
            |> simple_crossover # Crossover operator
            |> new_pop -> append!(P, new_pop)  # Add newly generated individuals to population
            |> uniform_mutation! # apply mutation operator
            |> P -> begin map(p -> p.fitness = p |> 𝓕, P); P end # recalculate fitness of population after mutation
            |> P -> map(repair, P)  # repair infeasible solutions
            |> P -> sort(P, by= p -> p.fitness) # Sort my fitness
            |> P -> filter(isValid, P) # remove invalid solutions
            |> P -> P[1:n] # take top n
        )
        n_gens = n_gens - 1
    end
    savefig(plotGeneration!(draw_road(road,0,20),P,road,100),string("./gen-",n_gens))
    # P = filter(isFeasible,P)
    P = filter(i->high_proximity_distance(road,i.phenotype.genotype)==0,filter(i -> infeasible_distance(road,i.phenotype.genotype)==0,P))
    P
end
