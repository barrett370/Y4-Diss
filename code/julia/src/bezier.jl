import Base.*
import Base.+
import Base.Threads
using DataStructures
using Distributed
using MLStyle
import LazySets.convex_hull
using GPUArrays

include("utils.jl")

const ControlPoint = Point
const BezierCurve = Array{ControlPoint}

function (*)(a::Real, b::ControlPoint)
    ControlPoint(b.x * a, b.y * a)
end

function (+)(a::ControlPoint, b::ControlPoint)
    ControlPoint(b.x + a.x, b.y + a.y)
end

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

function Bezier2Bernstein(B::BezierCurve)

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
    #println("bezInt called")
    n = 7
    c = Channel(4^(n-1))
    main = Threads.@spawn bezInt(B1,B2,1,n,c)
    false_count = 0
    while isopen(c)
        res = take!(c)
        if res[1]
            println("Found intersection $res")
            return res
        else
            false_count = false_count + 1
            if false_count == 4^(n-1)
                #println("no intersect detected, all false, $false_count")
                return (false,([],[]))
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
#function bezInt(B1::BezierCurve, B2::BezierCurve, rdepth::Int) :: Bool
    #println("recurse started")
   # @show rdepth
    #@show "starting"
    if rdepth +1 > rdepth_max
        #"rdepth reached" |> println
        put!(ret_channel,false)
    end
    ε  = 2.5 # TODO tune param
    toRealArray = i -> [[float(p.x),float(p.y)] for p in i]
    if length(B1) < 2 || length(B2) < 2
        @show "error not enough control points"
        put!(ret_channel,false)
    else
        if length(convex_hull(B1 |> toRealArray) ∪ convex_hull(B2 |> toRealArray)) != 0 # Union of the convex hulls of the control points is non-empty
            # B1 and B2 are a "candidate pair"
            if diam(B1 ∪ B2) < ε
                #@show rdepth
                put!(ret_channel,(true,(B1,B2)))
            else # subdivides the curve with the larger diameter
    #            println("subdividing")
                if diam(B1) >= diam(B2)
                    #@show "splitting B1"
                    #B1_1 = [ B1[1:i](0.5) for i in 1:length(B1) ]
                    #B1_2 = [ B1[1:i](1) for i in [length(B1)-i for i in 0:length(B1)-1]]
                    (B1_1,B1_2) = deCasteljau(B1,0.5)
                    Threads.@spawn bezInt(B1_1,B2,rdepth+1,rdepth_max, ret_channel)
                    Threads.@spawn bezInt(B1_2,B2,rdepth+1,rdepth_max, ret_channel)
                    #GPUArrays.syncronize([
                    #    bezInt(B1_1,B2,rdepth+1,rdepth_max, ret_channel),
                    #    bezInt(B1_2,B2,rdepth+1,rdepth_max, ret_channel)
                    #])
                    #Threads.@spawnat :any bezInt(B1_1,deepcopy(B2),deepcopy(rdepth+1),rdepth_max, ret_channel)
                    #Threads.@spawnat :any bezInt(B1_2,deepcopy(B2),deepcopy(rdepth+1),rdepth_max, ret_channel)
                else
                    #@show "splitting B2"
                    #B2_1 = [ B2[1:i](0.5) for i in 1:length(B2) ]
                    #B2_2 = [ B2[1:i](1) for i in [length(B2)-i for i in 0:length(B2)-1]]
                    (B2_1,B2_2) = deCasteljau(B2,0.5)
                    Threads.@spawn bezInt(B1,B2_1,rdepth+1,rdepth_max, ret_channel)
                    Threads.@spawn bezInt(B1,B2_2,rdepth+1,rdepth_max, ret_channel)
                    #GPUArrays.syncronize([
                    #    bezInt(B1,B2_1,rdepth+1,rdepth_max, ret_channel),
                    #bezInt(B1,B2_2,rdepth+1,rdepth_max, ret_channel)])
                    #Threads.@spawnat :any bezInt(deepcopy(B1),B2_1,deepcopy(rdepth+1),rdepth_max, ret_channel)
                    #Threads.@spawnat :any bezInt(deepcopy(B1),B2_2,deepcopy(rdepth+1),rdepth_max, ret_channel)
                end
                #@show "created tasks"

                #t1_channel = Channel(1)
                #t2_channel = Channel(1)
                #t3_channel = Channel(1)
                #t4_channel = Channel(1)
                #println("creating async tasks")
                #t1 = @task bezInt(B1_1,B2_1,rdepth+1,rdepth_max, ret_channel)
                #t2 = @task bezInt(B1_1,B2_2,rdepth+1,rdepth_max, ret_channel)
                #t3 = @task bezInt(B1_2,B2_1,rdepth+1,rdepth_max, ret_channel)
                #t4 = @task bezInt(B1_2,B2_2,rdepth+1,rdepth_max, ret_channel)
                #   #return bezInt(B1_1,B2_1,rdepth+1) || bezInt(B1_1,B2_2,rdepth+1) || bezInt(B1_2,B2_1,rdepth+1) || bezInt(B1_2,B2_2,rdepth+1)

                #tasks = [t1,t2,t3,t4]
                #tasks = [t1,t2]
    #           # println("spawning subprocesses")
                #for task in tasks
                #    schedule(task)
                #end

            end
        else
            println("B1 and B2 are not candidates therefore, cannot intersect.")
            #@show "initial individuals are not candidates"
            put!(ret_channel,false)
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
    println("Entering while")
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
