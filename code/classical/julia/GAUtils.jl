include("bezier.jl")
include("roadNetwork.jl")
include("utils.jl")

struct Phenotype
    source::Point
    direction_maintenance_points::Array{Real}
    genotype::BezierCurve
    goal::Point
end
mutable struct Individual
    phenotype::Phenotype
    fitness::Real
end


function getGenotypeString(genotype::BezierCurve)::Array{Real}
    genotype_str = []
    for point in genotype
        append!(genotype_str, point.x)
        append!(genotype_str, point.y)
    end
    genotype_str
end

MAX_P = 4


function generatePopulation(n::Integer, start::Point, goal::Point, r::Road)::Array{Individual}
    x_distance = abs(start.x - goal.x)
    y_distance = abs(start.y - goal.y)
    P = []
    for i in 1:n
        ps = [start]
        for i in 1:rand(1:MAX_P)
            new_x = ps[end].x + rand(0.2:1/n:x_distance / n)
            if new_x > goal.x
                new_x = goal.x
            end
            new_y = ps[end].y + rand(-(y_distance / n):1/n:(y_distance / n))
            if r.Ỹ(new_x, new_y) > 1
                new_y = r.boundary_2(new_x)
            end
            if new_y > goal.y
                new_y = goal.y
            end

            append!(ps,[ControlPoint(
                    new_x,
                    new_y
            )])
            if new_x  >= goal.x && new_y >= goal.y
                break
            end
        end
        append!(ps, [goal])
        append!(P, [Individual(Phenotype(start, [], BezierCurve(ps), goal), 0)])
    end
    P
end
