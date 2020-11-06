
using Plots; plotly()
include("./roadNetwork.jl")


mutable struct Gene
	val:: Float64
end
mutable struct Point
	x :: Float64
	y :: Float64
end

mutable struct Route
    path::Array{Point}
end
	
mutable struct Genotype
	genes :: Array{Point}
end

mutable struct Phenotype
	start_node:: Point
	maintenence_point:: Float64 # Angle
	control_points :: Genotype
end

mutable struct Population
	individuals :: Array{Genotype}
end

#termination_flag:: Bool = false;

function GA(RN::RN, sn::Int64, en::Int64)
	error("Not implemented")
end
function GA()
	A, B, C, D = Point(0.0,0.5),Point(3.0,0.5),Point(2.0,0.5),Point(4.0,0.5)
	popSize = 1;
	generation = 0;
	route = Route(
	    [A,B,C,D]
	)
	pop = init_pop(popSize,[route])
	@show pop
	plotCurve(pop.individuals[1],route)
end


function init_pop(n,routes:: Array{Route}) :: Population
	# Pop is of size n with each having a variable g genes (control points) each represented as t in:
	# B(t) = P0 + t(P1 - P0) = (1-t)P0 + t*P1
	pop:: Population= Population([])
	for i in 1:n # for each pop member
		genotype:: Genotype= Genotype([])
		for point in routes[i].path
			genotype.genes = push!(genotype.genes, Point(point.x,0.5))

		end
		pop.individuals= push!(pop.individuals,genotype)
	end
	pop
end

fitness(pop::Array{Route}) = map(length, pop.path)

function plotCurve(genotype::Genotype, route::Route)
	p = plot(ylim=(0,1))
	for point in genotype.genes
		plot!(p,[point.x], [point.y],seriestype = :scatter)
	end
	steps = 100
	nb = length(genotype.genes)-1 # Number of basis
	bs = [zeros(2,r) for r=length(nb)+1:-1:0
	for t in LinRange(0,1,steps)	
		for i=1:nb
			for j=0:nb-i
				new_b = (1-t)*bs
			end
		end
	end
	savefig(p,"plot")
end

GA()
