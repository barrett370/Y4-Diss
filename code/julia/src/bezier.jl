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
    for i = 1:length(curve) - 1
        l += √((curve[i].x - curve[i + 1].x)^2 + (curve[i].y - curve[i + 1].y)^2)
    end
    l
end

function bezLength(c::BezierCurve)::Real
    n = length(c)
    l =
        (
            2 * chord_length(c) +
            (n - 1) * polygon_length(c)
        ) / (n + 1)
    return l
end


function diam(X::Array{Point}) ::Real
    dist(a,os) = [√((a.x - b.x)^2 + (a.y - b.y)^2) for b in os]
    dist_matrix = [dist(a,X) for a in X]
    dist_matrix |> Iterators.flatten |> collect |> maximum

end

#function bezInt(B1::BezierCurve,B2::BezierCurve) :: Bool
#    bezInt(B1,B2,1)[1]
#end

function bezInt(B1::BezierCurve,B2::BezierCurve) :: Tuple{Bool,Tuple{BezierCurve,BezierCurve}}
    @debug "bezInt called"
    n = 7
    c = Channel(4^(n-1))
    main = Threads.@spawn bezInt(B1,B2,1,n,c)
    @debug "spawned main process"
    false_count = 0
    while isopen(c)
        res = take!(c)
        if res[1]
            @debug "Found intersection $res"
            return res
        else
            false_count = false_count + 1
            if length(res) > 1
                if res[2] == "non-candidate"
                    @warn "returning due to non-candidacy"
                    return (false,([],[]))
                end
           else 
                if false_count == 4^(n-1)
                    #println("no intersect detected, all false, $false_count")
                    return (false,([],[]))
                end
            end
            
        end
    end
    #println("no intersect detected, c closed")
    return false
end

function deCasteljau(B::BezierCurve,t::Real)::Tuple{BezierCurve,BezierCurve}
    ([ B[1:i](t) for i in 1:length(B) ],[ B[i:length(B)](1-t) for i in length(B):-1:1])
end

function bezInt(B1::BezierCurve, B2::BezierCurve, rdepth::Int,rdepth_max,ret_channel::Channel)
    if rdepth +1 > rdepth_max
        @warn "rdepth reached" 
        put!(ret_channel,false)
    end
    ε  = 2.5 # TODO tune param
    toRealArray = i -> [[float(p.x),float(p.y)] for p in i]
    toLuxPoints = b -> map(p-> Luxor.Point(p[1],p[2]),b)
    if length(B1) < 2 || length(B2) < 2
        @show "error not enough control points"
        put!(ret_channel,false)
    else
        #if length(convex_hull(B1 |> toRealArray) ∪ convex_hull(B2 |> toRealArray)) != 0 # Union of the convex hulls of the control points is non-empty
        @debug "testing hulls"
        dupe_points = length((B1 |> toRealArray) ∩ (B2 |> toRealArray)) != 0
        if !dupe_points
            hull_intersection = length(filter(each -> each == 1,
                         [Luxor.isinside(p, B1 |> toRealArray |> convex_hull |> toLuxPoints) for p in B2 |> toRealArray |> convex_hull |> toLuxPoints] ∩
                                          [Luxor.isinside(p, B2 |> toRealArray |> convex_hull |> toLuxPoints) for p in B1|> toRealArray |> convex_hull  |> toLuxPoints])) != 0
        else
            @debug "setting intersection to default (true)"
            hull_intersection = true
        end
        

        if hull_intersection
            # B1 and B2 are a "candidate pair"
            @debug "B1 and B2 are a candidate pair"
            if diam(B1 ∪ B2) < ε
                #@show rdepth
                put!(ret_channel,(true,(B1,B2)))
            else # subdivides the curve with the larger diameter
    #            println("subdividing")
                if diam(B1) >= diam(B2)
                    (B1_1,B1_2) = deCasteljau(B1,0.5)
                    Threads.@spawn bezInt(B1_1,B2,rdepth+1,rdepth_max, ret_channel)
                    Threads.@spawn bezInt(B1_2,B2,rdepth+1,rdepth_max, ret_channel)
                else
                    (B2_1,B2_2) = deCasteljau(B2,0.5)
                    Threads.@spawn bezInt(B1,B2_1,rdepth+1,rdepth_max, ret_channel)
                    Threads.@spawn bezInt(B1,B2_2,rdepth+1,rdepth_max, ret_channel)
                end
                #@show "created tasks"


            end
        else
            @warn "B1 and B2 are not candidates therefore, cannot intersect."
            #@show "initial individuals are not candidates"
            put!(ret_channel,(false,"non-candidate"))
        end
        
    end
    return
end



function YapInt(F::BezierCurve, G::BezierCurve) :: Bool
    Q₀ = Queue{Tuple{BezierCurve,BezierCurve}}() # macro queue
    Q₁ = Queue{Tuple{BezierCurve,BezierCurve}}() # micro queue
    Δ = 1 # TODO set this properly
    ε = 0.7

    toRealArray = i -> [[float(p.x),float(p.y)] for p in i]
    toPointArray = i -> [ Point(i[1],i[2]) ]
    if diam((convex_hull(F |> toRealArray ) ∪ convex_hull(G |> toRealArray ))[1] |> toPointArray) < Δ # macro pair
        enqueue!(Q₀,(F,G))
    else
        enqueue!(Q₁,(F,G))
    end


    # A pair (F,G) is micro if diam(convex_hull(F) ∪ convex_hull(G)) < Δ⋆, macropair otherwise
    debug_counter = 10
    while (length(Q₀) > 0 || lenght(Q₁) > 0) && debug_counter > 0
        debug_counter = debug_counter -1
        if length(Q₀) > 0
            println("taking from Q₀ $(length(Q₀))")
            (F,G) = dequeue!(Q₀)
            if length(convex_hull(F |> toRealArray) ∪ convex_hull(G |> toRealArray)) != 0 # Union of the convex hulls of the control points is non-empty

                if diam(F ∪ G) < ε
                    return true
                else
                    if diam(F) > diam(G)

                        F₀ = [ F[1:i](0.5) for i in 1:length(F) ]
                        F₁ = [ F[1:i](1) for i in [length(F) - i for i in 0:length(F)-1]]

                        if diam((convex_hull(F₀ |> toRealArray ) ∪ convex_hull(G |> toRealArray ))[1] |> toPointArray) < Δ # macro pair
                           println("enqueue 1")
                            enqueue!(Q₀,(F₀,G))
                        else
                           println("enqueue 2")
                            enqueue!(Q₁,(F₀,G))
                        end

                        if diam((convex_hull(F₁ |> toRealArray ) ∪ convex_hull(G |> toRealArray ))[1] |> toPointArray) < Δ # macro pair
                           println("enqueue 3")
                            enqueue!(Q₀,(F₁,G))
                        else

                           println("enqueue 4")
                            enqueue!(Q₁,(F₁,G))
                        end
                    else

                        G₀ = [ G[1:i](0.5) for i in 1:length(G) ]
                        G₁ = [ G[1:i](1) for i in [length(G) - i for i in 0:length(G)-1]]

                        if diam((convex_hull(G₀ |> toRealArray ) ∪ convex_hull(G |> toRealArray ))[1] |> toPointArray) < Δ # macro pair
                            enqueue!(Q₀,(G₀,F))
                           println("enqueue 5")
                        else
                           println("enqueue 6")
                            enqueue!(Q₁,(G₀,F))
                        end

                        if diam((convex_hull(G₁ |> toRealArray ) ∪ convex_hull(F |> toRealArray ))[1] |> toPointArray) < Δ # macro pair
                           println("enqueue 7")
                            enqueue!(Q₀,(G₁,F))
                        else
                           println("enqueue 8")
                            enqueue!(Q₁,(G₁,F))
                        end

                    end



                end

            else
                return false
            end
        else
            (F,G) = dequeue!(Q₁)
            return false
        end
    end
    return false



end
