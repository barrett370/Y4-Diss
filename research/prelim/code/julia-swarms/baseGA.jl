
include("./roadNetwork.jl")

mutable struct Route
    start_node::Int64
    end_node::Int64
    path::Array{Int64}
end

function GA(RN::RN, sn::Int64, en::Int64)

    popSize = 10
    generation = 0
end


function init_pop(n,sn,en,rn)

    pop = []
    for i in 1..n
            append!(pop, Route(
                sn,
                en,
                
            ))
    end

end

fitness(pop::Array{Route}) = map(length, pop.path)
