import Base.*
import Base.+
import Base.Threads
using DataStructures
using Distributed
using MLStyle
import LazySets.convex_hull
using Luxor
#   using GPUArrays

include("utils.jl")

const ControlPoint = Point
const BezierCurve = Array{ControlPoint}

function (*)(a::Real, b::ControlPoint)
    ControlPoint(b.x * a, b.y * a)
end

function (+)(a::ControlPoint, b::ControlPoint)
    ControlPoint(b.x + a.x, b.y + a.y)
end

#function convert(::Type{BezierCurve}, i::Individual)
#  i.phenotype.genotype
#end

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

function chord_length(curve::BezierCurve)
    first = curve[1]
    last = curve[end]
    √((first.x - last.x)^2 + (first.y - last.y)^2)
end

function polygon_length(curve::BezierCurve)
    l = 0
    for i = 1:length(curve)-1
        l += √((curve[i].x - curve[i+1].x)^2 + (curve[i].y - curve[i+1].y)^2)
    end
    l
end

function bezLength(c::BezierCurve)::Real
    n = length(c)
    l = (2 * chord_length(c) + (n - 1) * polygon_length(c)) / (n + 1)
    return l
end


function diam(X::Array{Point})::Real
    dist(a, os) = [√((a.x - b.x)^2 + (a.y - b.y)^2) for b in os]
    dist_matrix = [dist(a, X) for a in X]
    dist_matrix |> Iterators.flatten |> collect |> maximum

end

toRealArray = i -> [[float(p.x), float(p.y)] for p in i]

function bezInt(
    B1::BezierCurve,
    B2::BezierCurve,
)::Tuple{Bool,Tuple{BezierCurve,BezierCurve}}
    @debug "bezInt called"
    if B2 |> toRealArray == zeros(B2 |> length)
        return (false, ([], []))
    end

    #n = floor(1.4 * max(B1 |> length, B2 |> length))
    n = 15
    main = bezInt(B1, B2, 1, n)
    return main
end

function deCasteljau(B::BezierCurve, t::Real)::Tuple{BezierCurve,BezierCurve}
    (
        [B[1:i](t) for i = 1:length(B)],
        [B[i:length(B)](1 - t) for i = length(B):-1:1],
    )
end


function clear_previous_checks()
	previous_checks = Dict{
	    Tuple{BezierCurve,BezierCurve},
	    Tuple{Bool,Tuple{BezierCurve,BezierCurve}},
	}()
end

function bbox(b::BezierCurve)

	xs = map(p -> p.x,b)
	ys = map(p -> p.y,b)

	min_x = xs |> minimum
	max_x = xs |> maximum
	min_y = ys |> minimum
	max_y = ys |> maximum

	box = Luxor.BoundingBox(Luxor.Point(min_x,min_y),Luxor.Point(max_x,max_y))

	box

end

function bezInt(B1::BezierCurve, B2::BezierCurve, rdepth::Int, rdepth_max)
    if rdepth + 1 > rdepth_max
        @debug "rdepth reached"
        previous_checks[(B1, B2)] = (false, ([], []))
        return (false, ([], []))
    end
    ε = 2 # TODO tune param
    toLuxPoints = b -> map(p -> Luxor.Point(p[1], p[2]), b)
    if length(B1) < 2 || length(B2) < 2
        @error "error not enough control points"
        previous_checks[(B1, B2)] = (false, ([], []))
        return (false, ([], []))
    else
        if (B1, B2) in keys(previous_checks)
            @debug "found in previous checks"
            return previous_checks[(B1, B2)]
        elseif (B2, B1) in keys(previous_checks)
            @debug "found in previous checks"
            return previous_checks[(B2, B1)]
        end
        @debug "not found in previous checks"
        dupe_points = length((B1 |> toRealArray) ∩ (B2 |> toRealArray)) != 0
        if !dupe_points && length(B1) > 1 && length(B2) > 1
            @debug "no dupe points"
            #ts = rand(0:0.05:1, 500)
            #B1_points = map(t -> B1(t), ts)
            #B2_points = map(t -> B2(t), ts)
            #hull_intersection =
            #    length(
            #        filter(
            #            each -> each == 1,
            #            [
            #                Luxor.isinside(
            #                    p,
            #                    #B1 |> toRealArray |> convex_hull |> toLuxPoints,
			#					B1 |> bbox,
            #                    allowonedge = true,
            #                ) for p in
            #                B2_points |>
            #                toRealArray |>
            #                convex_hull |>
            #                toLuxPoints
            #            ] ∪ [
            #                Luxor.isinside(
            #                    p,
            #                    #B2 |> toRealArray |> convex_hull |> toLuxPoints,
			#					B2 |> bbox,
            #                    allowonedge = true,
            #                ) for p in
            #                B1_points |>
            #                toRealArray |>
            #                convex_hull |>
            #                toLuxPoints
            #            ],
            #        ),
            #    ) != 0
				#hull_intersection = true
			hull_intersection = Luxor.boundingboxesintersect(B1 |> bbox, B2|> bbox)
        else
            @debug "setting intersection to default (true)"
            hull_intersection = true
        end


        if hull_intersection
            # B1 and B2 are a "candidate pair"
            @debug "B1 and B2 are a candidate pair"
            if diam(B1 ∪ B2) < ε
                previous_checks[(B1, B2)] = (true, (B1, B2))
                return (true, (B1, B2))
            else # subdivides the curve with the larger diameter
                tasks::Array{Task} = []
                if diam(B1) >= diam(B2)
                    (B1_1, B1_2) = deCasteljau(B1, 0.5)
                    append!(
                        tasks,
                        [
                            Threads.@spawn bezInt(
                                B1_1,
                                B2,
                                rdepth + 1,
                                rdepth_max,
                            )
                        ],
                    )
                    append!(
                        tasks,
                        [
                            Threads.@spawn bezInt(
                                B1_2,
                                B2,
                                rdepth + 1,
                                rdepth_max,
                            )
                        ],
                    )
                else
                    (B2_1, B2_2) = deCasteljau(B2, 0.5)
                    append!(
                        tasks,
                        [
                            Threads.@spawn bezInt(
                                B1,
                                B2_1,
                                rdepth + 1,
                                rdepth_max,
                            )
                        ],
                    )
                    append!(
                        tasks,
                        [
                            Threads.@spawn bezInt(
                                B1,
                                B2_2,
                                rdepth + 1,
                                rdepth_max,
                            )
                        ],
                    )
                end
                for task in tasks
                    res = fetch(task)
                    if res[1]
                        previous_checks[(B1, B2)] = res
                        return res
                    end
                end
                previous_checks[(B1, B2)] = (false, ([], []))
                return (false, ([], []))

            end
        else
            @debug "B1 and B2 are not candidates therefore, cannot intersect."
            previous_checks[(B1, B2)] = (false, ([], []))
            return (false, ([], []))
        end
    end
end
