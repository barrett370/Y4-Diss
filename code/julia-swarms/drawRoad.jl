
using Plots; plotly()
include("roadNetwork.jl")
include("BaseGA.jl")

function plot_road_curve!(plt,i::Integer,c::BezierCurve,n::Integer,r::Road)
    ps_x = []
    ps_y = []
    for x in range(0,1,step=1/n)
        C = c(x)
        append!(ps_x,C[1])
        append!(ps_y,r.Ỹ(C[1],C[2]))
    end
    display(plot!(plt,ps_x,ps_y,label=string("Individual-",i)))
end

function draw_road(r::Road,s::Real,e::Real)
    rg = plot(r.boundary_1,s,e,linewidth=3,linecolor=:black,legend=false)
    plot!(rg,r.boundary_2,s,e,linewidth=3,linecolor=:black)
end

boundary1(x) = sin(0.3*x)
boundary2(x) = sin(0.35*x)+4
road = Road(
        boundary1,
        boundary2
)

start_point = Point(0,10)
goal_point = Point(19,10)


# Draw Road
road_graph = draw_road(road,0,20)
