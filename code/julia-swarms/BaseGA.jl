include("bezier.jl")

struct Point
    x::Real
    y::Real
end

struct Phenotype
    source::Point
    direction_maintenance_points::Array{Real}
    genotype::BezierCurve
    goal::Point
end



function getGenotypeString(genotype::BezierCurve)::Array{Real}
    genotype_str = []
    for point in genotype.control_points
        append!(genotype_str, point.x)
        append!(genotype_str, point.y)
    end
    genotype_str
end

function plotIndividual(p::Phenotype,n=100)
    plot_curve(p.genotype,n)
end


function plotGeneration(P::Array{Phenotype},n=100)
    plt = plot()
    for i in 1:length(P)
        plot_curve!(plt,i,P[i].genotype,n)
    end
    display(plt)
end

MAX_P = 5


function generatePopulation(n::Integer,start::Point,goal::Point) :: Array{Phenotype}
    x_distance = abs(start.x-goal.x)
    y_distance = abs(start.y-goal.y)
    P = []
    for i in 1:n
        ps = [ControlPoint(start.x,start.y)]
        for i in 1:rand(1:MAX_P)
            new_x = ps[end].x + rand(0.0:.1:x_distance/n)
            if new_x > goal.x
                new_x = goal.x
            end
            new_y = ps[end].y + 0.6*rand(0.0:.01:y_distance/n)
            if new_y > 1
                new_y = 1
            end
            if new_y > goal.y
                new_y = goal.y
            end

            append!(ps,[ControlPoint(
                    new_x,
                    new_y
            )])
            if new_x == goal.x && new_y == goal.y
                break
            end
        end
        append!(ps,[ControlPoint(goal.x,goal.y)])
        append!(P,[Phenotype(start,[],BezierCurve(ps),goal)])
    end
    P
end
