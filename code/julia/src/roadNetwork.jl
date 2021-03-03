include("utils.jl")
include("bezier.jl")
import Graphs
import LightGraphs
import SimpleWeightedGraphs


##  A Road is defined using the Road coordinate system (X',Y') where Y' lim = width(road


abstract type Obstacle end

struct Circle <: Obstacle
    r::Real
    centre::Point
end

struct Rectangle <: Obstacle
    h::Real
    w::Real
    origin::Point
end

function (c::Circle)(θ::Real)
    c.centre.x + c.r * cos(θ), c.centre.y + c.r * sin(θ)
end


struct Road
    boundary_1::Function
    boundary_2::Function
    obstacles::Array{Obstacle}
    length::Real
    function Road(b1, b2, obs,len)
        new(b1, b2, obs,len)
    end
    #TODO implement road length
end

struct Intersection
    name::Char
end

#struct RoadNetwork <: AbstractGraph{Char,}
#    vertices::Array{Intersection}
#    edges::Array{Tuple{Intersection,Intersection,Road}}
#end

function graphToLightGraph(g::GenericGraph)::SimpleWeightedDiGraph
    g_light = SimpleWeightedDiGraph(length(g.vertices))
    for e in g.edges
        LightGraphs.add_edge!(g_light, e.source, e.target, e.attributes["road"].length)
    end
    g_light
end

function createRoadGraph(n_verts::Real, abstract_edges::Array{Tuple{Int64,Int64,Road}})
    edges = []
    i = 1
    for e in abstract_edges
        new_e =Graphs.ExEdge(i,e[1],e[2])
        new_e.attributes = Dict("road"=>e[3])
        append!(edges, [new_e] )
    end
    Graphs.graph(vcat(1:n_verts), edges)
end

get_edgeWeights(g::GenericGraph) = map(e -> e.attributes["road"].length, g.edges) 
