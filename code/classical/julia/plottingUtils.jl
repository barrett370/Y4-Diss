using Plots
# plotlyjs()
gr()
include("roadNetwork.jl")
include("utils.jl")
include("GAUtils.jl")


# What a bloody messs TODO Cleanup this mess



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


function plotGeneration!(plt, P::Array{Individual}, n = 100, g = -1)
    for i = 1:length(P)
        plt = plot_curve!(plt, i, P[i].phenotype.genotype, n)
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
        # rs_cords = r.Ỹ(C.x, C.y)
        # append!(ps_x, rs_cords[1])
        # append!(ps_y, rs_cords[2])
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    if i == 1 # If fittest individual
        plot_control_points!(plt, c)
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
            # for i = 1:length(points[1])
            #     # rs_cords = r.Ỹ(points[1][i], points[2][i])
            #     points[1][i] = rs_cords[1]
            #     points[2][i] = rs_cords[2]
            # end
            # elseif typeof(o) == Rectangle
            #     points = get_rectangle(o)
            #     for i = 1:length(points.x)
            #         rs_coords = r.Ỹ(points.x[i], points.y[i])
            #         points.x[i] = rs_coords[1]
            #         points.y[i] = rs_coords[2]
            #     end
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

function plot_curve_bounds!(plt,i::Integer,c::BezierCurve,n::Integer,t_bound::Real,colour="None")
    if t_bound > 1 || t_bound < 0
        println("Error t_bound must be in range 0<=t<=1")
        return
    end
    ps_x, ps_y = [], []
    for x in range(0, t_bound, step = 1 / n)
        C = c(x)
        append!(ps_x, C.x)
        append!(ps_y, C.y)
    end
    if colour != "None"
        plot!(plt, ps_x, ps_y, label = string("Individual-", i),legend=false,color=colour)
    else
        plot!(plt, ps_x, ps_y, label = string("Individual-", i),legend=false)
    end
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

function plot_control_points!(plt, c::BezierCurve)
    for p in c
        plot!(plt, (p.x,p.y), seriestype = :scatter, legend = false)
    end
end

function plot_generation_gif(road::Road, P::Array{Individual})
    plt = plot()
    plt = draw_road(road,0,20)
    ci = 1
    colours = [:red,:blue,:green,:yellow]
    for i in P
        for p in i.phenotype.genotype
            plot!(plt,[(p.x,p.y)],seriestype=:scatter,color=colours[ci])
        end
        ci = ci + 1
    end
    ci=1
    anim = @animate for i ∈ 0:0.1:1
        for p in P
            plot_curve_bounds!(plt,1,p.phenotype.genotype,100,i,colours[ci])
            ci = ci + 1
        end
        ci = 1
    end

    gif(anim,"anim1.gif",fps=2)
end
