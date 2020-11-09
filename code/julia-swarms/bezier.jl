import Base.*
import Base.+
using Plots


struct ControlPoint
    x::Float64
    y::Float64
end

struct BezierCurve
    control_points::Array{ControlPoint}
end

function (*)(a::Real, b::ControlPoint)
    ControlPoint(b.x * a, b.y * a)
end



function (+)(a::ControlPoint, b::ControlPoint)
    ControlPoint(b.x + a.x, b.y + a.y)
end

# function (curve::BezierCurve)(t::Real)
#     n = length(curve.control_points)
#     acc = ControlPoint(0,0)
#     for i = 1:n
#         acc += binomial(n, i) * ((1 - t)^(n - i)) * (t^i) * curve.control_points[i]
#     end
#     return acc
# end

function (curve::BezierCurve)(t::Real)::ControlPoint
    n = length(curve.control_points)
    if n == 1
        return curve.control_points[1]::ControlPoint
    else
        b1::BezierCurve = BezierCurve(curve.control_points[1:end-1])
        b2::BezierCurve = BezierCurve(curve.control_points[2:end])
        return ((1 - t) * b1(t)) + (t * b2(t))
    end
end

function plot_curve(c::BezierCurve, n::Integer)
    ps_x = []
    ps_y = []
    for x in range(0, 1, step = 1 / n)
        C = c(x)
        append!(ps_x, C[1])
        append!(ps_y, C[2])
    end
    plot(ps_x, ps_y)
end

function plot_curve!(plt, i::Integer, c::BezierCurve, n::Integer)
    ps_x = []
    ps_y = []
    for x in range(0, 1, step = 1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    (plot!(plt, ps_x, ps_y, label = string("Individual-", i)))
end
