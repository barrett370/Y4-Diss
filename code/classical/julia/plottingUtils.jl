using Plots
# plotlyjs()
gr()
include("roadNetwork.jl")
include("utils.jl")
include("GAUtils.jl")

function plotIndividual(p::Individual, n = 100)
    plot_curve(p.phenotype.genotype, n)
end

function plotIndividual!(plt, p::Individual, road::Road, n = 100)
    plot_road_curve!(plt, 1, p.phenotype.genotype, n, road)
end


function plotGeneration(P::Array{Individual}, n = 100)
    plt = plot()
    for i = 1:length(P)
        plot_curve!(plt, i, P[i].phenotype.genotype, n)
    end
    display(plt)
end

function plotGeneration!(plt, P::Array{Individual}, road::Road, n = 100, g = -1)
    for i = 1:length(P)
        plt = plot_road_curve!(plt, i, P[i].phenotype.genotype, n, road)
    end
    if g != -1
        plt = plot!(plt, title = string("Generation-", g))
    end
    plt
end

function plot_road_curve!(plt, i::Integer, c::BezierCurve, n::Integer, r::Road)
    ps_x = []
    ps_y = []
    for x in range(0, 1, step = 1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, r.Ỹ(C.x, C.y))
    end
    if i == 1

        plot!(plt, ps_x, ps_y, label = string("Individual-", i), lw = 3)
    else
        plot!(plt, ps_x, ps_y, label = string("Individual-", i))
    end
end

function draw_road(r::Road, s::Real, e::Real)
    rg = plot(r.boundary_1, s, e, linewidth = 3, linecolor = :black, legend = false)
    plot!(rg, r.boundary_2, s, e, linewidth = 3, linecolor = :black)
    for o in r.obstacles

        # @match o begin
        #     _::Type{Circle} => points = points = get_circle(o)
        #     _::_ => break
        # end
        if typeof(o) == Circle
            points = get_circle(o)
            for i = 1:length(points[1])
                points[2][i] = r.Ỹ(points[1][i], points[2][i])
            end
        elseif typeof(o) == Rectangle
            points = get_rectangle(o)
            for i = 1:length(points.x)
                points.y[i] = r.Ỹ(points.x[i], points.y[i])
            end
        end

        plot!(
            rg,
            points,
            seriestype = [:shape],
            lw = 0.5,
            c = :red,
            linecolor = :black,
            legend = false,
        )
    end
    rg
end

function get_curve(c::BezierCurve, n = 500)
    ps_x, ps_y = [], []
    for x in range(0, 1, step = 1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    ps_x, ps_y
end

function get_circle(c::Circle)
    ps_x, ps_y = [], []
    for t ∈ LinRange(0, 2π, 500)
        C = c(t)
        append!(ps_x, C[1])
        append!(ps_y, C[2])
    end
    ps_x, ps_y
end

function get_rectangle(r::Rectangle)
    Shape(r.origin.x .+ [0, r.w, r.w, 0], r.origin.y .+ [0, 0, r.h, r.h])
end

function plot_curve(c::BezierCurve, n::Integer)
    ps_x, ps_y = [], []
    for x in range(0, 1, step = 1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    plot(ps_x, ps_y)
end

function plot_curve!(plt, i::Integer, c::BezierCurve, n::Integer)
    ps_x, ps_y = [], []
    for x in range(0, 1, step = 1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    plot!(plt, ps_x, ps_y, label = string("Individual-", i))
end
