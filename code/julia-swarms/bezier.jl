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

function (*)(a::Float64, b::ControlPoint)
    ControlPoint(b.x * a, b.y * a)
end



function (+)(a::Tuple{Real,Real}, b::ControlPoint)
    (b.x + a[1], b.y + a[2])
end

function (curve::BezierCurve)(t::Real)
    n = length(curve.control_points)
    acc = (0, 0)
    for i = 1:n
        acc += binomial(n, i) * (1 - t)^(n - i) * t^i * curve.control_points[i]
    end
    return acc
end

function plot_curve(c::BezierCurve,n::Integer)
    ps_x = []
    ps_y = []
    for x in range(0,1,step=1/n)
        C = c(x)
        append!(ps_x,C[1])
        append!(ps_y,C[2])
    end
    plot(ps_x,ps_y,ylims=(0,1))
end

function plot_curve!(plt,i::Integer,c::BezierCurve,n::Integer)
    ps_x = []
    ps_y = []
    for x in range(0,1,step=1/n)
        C = c(x)
        append!(ps_x,C[1])
        append!(ps_y,C[2])
    end
    (plot!(plt,ps_x,ps_y,ylims=(0,1),label=string("Individual-",i)))
end
