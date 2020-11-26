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


# function BezierCircle()
#     n =3
#     α= 2π/n
#     L = (4/3) * tan(π/(2*n))
#     P0 = Point(0, 1)
#     P1 = Point((0, 1) .+ L .* (0, 1))
#     P2 = Point((cos(α), sin(α)) .- L .* (-sin(α), cos(α)))
#     P3 = Point(cos(α),sin(α))
#     BezierCurve([P0,P1,P2,P3])
# end



function (c::Circle)(θ::Real)
    c.centre.x + c.r * cos(θ), c.centre.y + c.r * sin(θ)
end


struct Road
    boundary_1::Function
    boundary_2::Function
    # Ỹ :: Function
    obstacles::Array{Obstacle}
    function Road(b1, b2, obs)
        # Y = function Y(x,y)
        #
        #     b1_x = b1(x)
        #     b2_x = b2(x)
        #
        #     y = (√(y-b1_x)^2)/(√(b2_x-b1_x)^2)
        #     (x,y)
        # end
        # new(b1,b2,Y,obs)
        new(b1, b2, obs)
    end
end
