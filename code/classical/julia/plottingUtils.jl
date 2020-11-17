using Plots: plot, plot!,plotlyjs
plotlyjs()
include("roadNetwork.jl")
include("utils.jl")
include("GAUtils.jl")

function plotIndividual(p::Individual, n=100)
    plot_curve(p.phenotype.genotype, n)
end

function plotIndividual!(plt, p::Individual, road::Road, n=100)
    plot_road_curve!(plt, 1, p.phenotype.genotype, n, road)
end


function plotGeneration(P::Array{Individual}, n=100)
    plt = plot()
    for i in 1:length(P)
        plot_curve!(plt, i, P[i].phenotype.genotype, n)
    end
    display(plt)
end

function plotGeneration!(plt, P::Array{Individual}, road::Road, n=100)
    for i in 1:length(P)
        plot_road_curve!(plt, i, P[i].phenotype.genotype, n, road)
    end
    plt
end

function plot_road_curve!(plt, i::Integer, c::BezierCurve, n::Integer, r::Road)
    ps_x = []
    ps_y = []
    for x in range(0, 1, step=1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, r.Ỹ(C.x, C.y))
    end
    display(plot!(plt, ps_x, ps_y, label=string("Individual-", i)))
end

function draw_road(r::Road, s::Real, e::Real)
    rg = plot(r.boundary_1, s, e, linewidth=3, linecolor=:black, legend=false)
    plot!(rg, r.boundary_2, s, e, linewidth=3, linecolor=:black)
    for o in r.obstacles

        # @match o begin
        #     _::Type{Circle} => points = points = get_circle(o)
        #     _::_ => break
        # end
        if typeof(o) == Circle
                points = get_circle(o)
        end
                for i in 1:length(points[1])
                    points[2][i] = r.Ỹ(points[1][i],points[2][i])
                end
        plot!(rg,points,seriestype=[:shape], lw=0.5, c=:red, linecolor =:black,legend=false)
    end
    rg
end

function get_curve(c::BezierCurve,n=500)
    ps_x, ps_y = [], []
    for x in range(0, 1, step=1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    ps_x, ps_y
end

function get_circle(c::Circle)
    ps_x, ps_y = [],[]
    for t ∈ LinRange(0,2π,500)
        C = c(t)
        append!(ps_x,C[1])
        append!(ps_y,C[2])
    end
    ps_x,ps_y
end

function plot_curve(c::BezierCurve, n::Integer)
    ps_x, ps_y = [], []
    for x in range(0, 1, step=1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    plot(ps_x, ps_y)
end

function plot_curve!(plt, i::Integer, c::BezierCurve, n::Integer)
    ps_x, ps_y = [], []
    for x in range(0, 1, step=1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    plot!(plt, ps_x, ps_y, label=string("Individual-", i))
end
