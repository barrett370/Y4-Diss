include("GAUtils.jl")
include("geneticOperators.jl")

using Distributed
using SharedArrays
using StaticArrays
import Base.Threads

function PCGA(
    starts::Array{Point},
    goals::Array{Point},
    road::Road,
    multi_thread=true;
    n_gens::Real=1,
    n::Real=10,
    selection_method::SelectionMethod,
    mutation_method::MutationMethod
)


    current_plans = SharedArray{SVector{2*MAX_P,Float64}}(length(starts)) # Length of 12 as this is the max number of control points *2
    ret::Array{Individual} = []
    # Build tasks
    tasks::Array = []
    c = 1
    for (start, goal) in zip(starts, goals)
        @debug start, goal, c
        if multi_thread
            append!(tasks,
                    [Threads.@spawn PCGA(start,goal,road,current_plans,i=deepcopy(c),
                                         n_gens=n_gens,n=n,selection_method=selection_method,mutation_method=mutation_method)])
        else
            @warn "Not running in multithreaded mode"
            append!(ret,PCGA(start,goal,road,current_plans,i=deepcopy(c),
                                         n_gens=n_gens,n=n,selection_method=selection_method,mutation_method=mutation_method))
        end

        if c + 1 <= length(starts)
            c = c + 1
        end
    end
    if multi_thread
        @debug "fetching results"
        for task in tasks
            append!(ret, fetch(task))
            @debug "fetched result $ret"
        end
    end

    ret
end

function FinalCheck(route::Individual, os::SharedArray, i::Integer)::Bool
    for j in 1:length(os)
        if j != i
            if collisionDetection(route.phenotype.genotype, os[j] |> getGenotype)
                return false
            end
        end
    end
    return true
end


function PCGA(start::Point,
              goal::Point,
              road::Road,
              other_routes::SharedArray; i::Integer=0,
              n_gens::Real=1, n::Real=10,
              selection_method::SelectionMethod,
              mutation_method::MutationMethod)::Array{Individual}
    # Initialise population
    @debug "Size of other_routes = $(length(other_routes))"
    if start.y < road.boundary_1(start.x) || start.y > road.boundary_2(start.y) || goal.y < road.boundary_1(goal.x) || goal.y > road.boundary_2(goal.x)
        @error "ERROR, start of goal is outside of roadspace"
        return []
    end

    ngens_copy = deepcopy(n_gens)
    𝓕 = curry(curry(Fitness, road), other_routes) # Curry fitness function with road as this is a static attribute of the function. Allows for nicer piping of data.
    P = generatePopulation(n, start, goal, road)
    map(p -> p.fitness = p |> 𝓕, P) # Calculate fitness for initial population, map 𝓕 over all Individuals
    while n_gens > 0 && length(P) > 0# Replace with stopping criteria
        # savefig(plotGeneration!(draw_road(road,0,20),P,road,100,100-n_gens),string("./gifgen/gen-",100-n_gens))
        P = (P
            |> P -> selection(P, method=selection_method)  # Selection operator
            |> simple_crossover |> new_pop -> append!(P, new_pop)  ## Crossover operator & Add newly generated individuals to population
            |> P -> mutation!(P,road,method=mutation_method) # apply mutation operator
            |> P -> begin map(p -> p.fitness = p |> 𝓕, P); P end # recalculate fitness of population after mutation
            |> P -> map(repair, P)  # attempt repair of invalid solutions
            |> P -> sort(P, by=p -> p.fitness) # Sort my fitness
            |> P -> filter(isValid, P) # remove invalid solutions
            |> P -> P[1:minimum([n,length(P)])]# take top n
        )

        #P_filtered = filter(c -> FinalCheck(c, other_routes, i), P)
        #P_2filtered = filter(ind -> high_proximity_distance(road, ind.phenotype.genotype) == 0, filter(ind -> infeasible_distance(road, ind.phenotype.genotype) == 0, P_filtered))
        #if (n_gens -1 == 0 && P_2filtered |> length != 0) || n_gens -1 != 0
            n_gens -= 1
        #else
        #    @warn "extending gens, no valid routes found"
        #end
        @debug "accessing routes at $i"
        other_routes[i] = P[1] |> toSVector
        #TODO is this good?
        if P[1].fitness / √((start.x - goal.x)^2 + (start.y - goal.y)^2)  < 1.1
            @warn "Exiting early, within 10% of straight line fitness"
            break
        end
    end
#    savefig(plotGeneration!(draw_road(road,0,20),P,road,100),string("./gen-",n_gens))
    # if length(P) == 0
    #    return PCGA(start,goal,road,other_routes, i, ngens_copy,n)
    # end
    P_filtered = filter(c -> FinalCheck(c, other_routes, i), P)
    if P_filtered |> length  != 0
        P_2filtered = filter(ind -> high_proximity_distance(road, ind.phenotype.genotype) == 0, filter(ind -> infeasible_distance(road, ind.phenotype.genotype) == 0, P_filtered))
        if P_2filtered |> length  != 0
            @debug "Final solution $(P_2filtered[1])"
            return [P_2filtered[1]]
        else
            @warn "Cannot avoid infeasible space"
            return [P_filtered[1]]
        end
    else
        @warn "no non-colliding routes found"
        return [P[1]]
    end
    @error "No valid results"

end
