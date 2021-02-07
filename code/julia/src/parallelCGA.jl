include("GAUtils.jl")
include("geneticOperators.jl")

using Distributed
using SharedArrays
using StaticArrays

function PCGA(
    starts::Array{Point},
    goals::Array{Point},
    road::Road,
    n_gens::Real = 1,
    n::Real = 10,
)


    current_plans = SharedArray{SVector{6,Float64}}(n)
    ret::Array{Individual} = []
    # Build tasks
    tasks::Array{Task} = []
    i = 1
    for (start, goal) in zip(starts, goals)
        @show start, goal
        append!(tasks, [@task begin; PCGA(start,goal,road,current_plans,n_gens,n,i); end])
        i = i+1
    end
    for task in tasks
        schedule(task)
    end

    while ! istaskdone(tasks[end])
        wait()
    end

   current_plans



    #ret

end

function PCGA(start::Point, goal::Point, road::Road, other_routes::SharedArray{SVector{6,Float64}},i::Integer, n_gens::Real=1, n::Real=10) :: Array{Individual}
    # Initialise population
    if  start.y < road.boundary_1(start.x) || start.y > road.boundary_2(start.y) || goal.y < road.boundary_1(goal.x) || goal.y > road.boundary_2(goal.x)
        println("ERROR, start of goal is outside of roadspace")
        return []
    end
    𝓕 = curry(curry(Fitness,road),other_routes) # Curry fitness function with road as this is a static attribute of the function. Allows for nicer piping of data.
    P = generatePopulation(n, start, goal, road)
    map(p -> p.fitness = p |> 𝓕, P) # Calculate fitness for initial population, map 𝓕 over all Individuals
    while n_gens > 0 && length(P) > 0# Replace with stopping criteria
        # savefig(plotGeneration!(draw_road(road,0,20),P,road,100,100-n_gens),string("./gifgen/gen-",100-n_gens))
        P = (P
            |> roulette_selection  # Selection operator
            |> simple_crossover |> new_pop -> append!(P, new_pop)  ## Crossover operator & Add newly generated individuals to population
            |> uniform_mutation! # apply mutation operator
            |> P -> begin map(p -> p.fitness = p |> 𝓕, P); P end # recalculate fitness of population after mutation
            |> P -> map(repair, P)  # attempt repair of invalid solutions
            |> P -> sort(P, by= p -> p.fitness) # Sort my fitness
            |> P -> filter(isValid, P) # remove invalid solutions
            |> P -> P[1:minimum([n,length(P)])]# take top n
        )
        n_gens = n_gens - 1
        other_routes[i] = P[1] |> toSVector
    end
#    savefig(plotGeneration!(draw_road(road,0,20),P,road,100),string("./gen-",n_gens))
    # P = filter(i->high_proximity_distance(road,i.phenotype.genotype)==0,filter(i -> infeasible_distance(road,i.phenotype.genotype)==0,P))
    yeild()
end
