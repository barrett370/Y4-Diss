include("utils.jl")



##  A Road is defined using the Road coordinate system (X',Y') where Y' lim = width(road


abstract type Obstacle end

struct Circle <: Obstacle
    r :: Real
    centre :: Point
end

function (c::Circle)(θ::Real)
    c.centre.x + c.r * cos(θ) , c.centre.y + c.r * sin(θ)
end


struct Road
    boundary_1 :: Function
    boundary_2 :: Function
    Ỹ :: Function
    obstacles :: Array{Obstacle}
    function Road(b1,b2,obs)
        Y = function Y(x,y)
            y_b1 = b1(x)
            y_b2 = b2(x)
            y_b1 + √((y-y_b1)^2) / √((y_b1-y_b2)^2)
        end
        new(b1,b2,Y,obs)
    end
end
