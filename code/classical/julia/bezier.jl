import Base.*
import Base.+
using MLStyle
include("utils.jl")

const ControlPoint = Point
const BezierCurve = Array{ControlPoint}

function (*)(a::Real, b::ControlPoint)
    ControlPoint(b.x * a, b.y * a)
end

function (+)(a::ControlPoint, b::ControlPoint)
    ControlPoint(b.x + a.x, b.y + a.y)
end

function (curve::BezierCurve)(t::Real)::ControlPoint
    @match curve begin
        [p] => p
        _ => begin
            b1::BezierCurve = BezierCurve(curve[1:end-1])
            b2::BezierCurve = BezierCurve(curve[2:end])
            return ((1 - t) * b1(t)) + (t * b2(t))
        end
    end
end

function plot_curve(c::BezierCurve, n::Integer)
    ps_x , ps_y = [],[]
    for x in range(0, 1, step = 1 / n)
        C = c(x)
        append!(ps_x, C[1])
        append!(ps_y, C[2])
    end
    plot(ps_x, ps_y)
end

function plot_curve!(plt, i::Integer, c::BezierCurve, n::Integer)
    ps_x , ps_y = [],[]
    for x in range(0, 1, step = 1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    (plot!(plt, ps_x, ps_y, label = string("Individual-", i)))
end
