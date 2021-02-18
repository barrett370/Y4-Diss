include("utils.jl")

include("bezier.jl")


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
    function Road(b1, b2, obs)
        new(b1, b2, obs)
    end

    #TODO implement road length
end
