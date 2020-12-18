import Base.*
import Base.+
using MLStyle
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

function diam(X::Array{Point}) ::Real
    dist(a,os) = [√((a.x - b.x)^2 + (a.y - b.y)^2) for b in os]
    dist_matrix = [dist(a,X) for a in X]
    dist_matrix |> Iterators.flatten |> collect |> maximum

end

function bezInt(B1::BezierCurve,B2::BezierCurve) :: Bool
    bezInt(B1,B2,1)[1]
end

function bezInt(B1::BezierCurve,B2::BezierCurve) :: Tuple{Bool,Tuple{BezierCurve,BezierCurve}}
    bezInt(B1,B2,1)
end

function bezInt(B1::BezierCurve, B2::BezierCurve, rdepth::Int) :: Tuple{Bool,Tuple{BezierCurve,BezierCurve}}
#function bezInt(B1::BezierCurve, B2::BezierCurve, rdepth::Int) :: Bool
    if rdepth +1 > 10
        #println("recursion depth reached")
        return (false,([],[]))
    end
    ε  = 0.7 # TODO tune param
    toRealArray = i -> [[float(p.x),float(p.y)] for p in i]
    if length(B1) < 2|| length(B2) < 2 
        @show "error not enough control points"
        return (false,([],[]))
    end
    if length(convex_hull(B1 |> toRealArray) ∪ convex_hull(B2 |> toRealArray)) != 0 # Union of the convex hulls of the control points is non-empty
        # B1 and B2 are a "candidate pair"
        if diam(B1 ∪ B2) < ε
            #println("detected intersect between $B1 and $B2")
            #@show rdepth
            return (true,(B1,B2))
        else # subdivides the curve with the larger diameter


                B1_1 = [ B1[1:i](0.5) for i in 1:length(B1) ]
                B1_2 = [ B1[1:i](1) for i in [length(B1)-i for i in 0:length(B1)-1]]
                B2_1 = [ B2[1:i](0.5) for i in 1:length(B2) ]
                B2_2 = [ B2[1:i](1) for i in [length(B2)-i for i in 0:length(B2)-1]]
                branch1 = bezInt(B1_1,B2_1,rdepth+1) 
                if branch1[1]
                    return branch1
                end

                branch2 = bezInt(B1_1,B2_2,rdepth+1) 
                if branch2[1]
                    return branch2
                end

                branch3 = bezInt(B1_2,B2_1,rdepth+1) 
                if branch3[1]
                    return branch3
                end

                branch4 = bezInt(B1_2,B2_2,rdepth+1) 
                if branch4[1]
                    return branch4
                end
                #return bezInt(B1_1,B2_1,rdepth+1) || bezInt(B1_1,B2_2,rdepth+1) || bezInt(B1_2,B2_1,rdepth+1) || bezInt(B1_2,B2_2,rdepth+1)


#                return @async fetch(bezInt(B1_1,B2_1,rdepth+1)) || @async fetch(bezInt(B1_1,B2_2,rdepth+1)) || @async fetch(bezInt(B1_2,B2_1,rdepth+1)) || @async fetch(bezInt(B1_2,B2_2,rdepth+1))

        end
    else
        # B1 and B2 are not "candidates" therefore, cannot intersect.
        #@show "initial individuals are not candidates"
        return (false,([],[]))
    end
    return (false,([],[]))
end

#function bezInt(B1::BezierCurve, B2::BezierCurve, rdepth::Int) :: Tuple{Bool,Tuple{BezierCurve,BezierCurve}}
#    if rdepth +1 > 10
#        #println("recursion depth reached")
#        return false
#    end
#    ε  = 1 # TODO tune param
#    toRealArray = i -> [[float(p.x),float(p.y)] for p in i]
#    if length(B1) < 2|| length(B2) < 2 
#        @show "error not enough control points"
#        return false
#    end
#    if length(convex_hull(B1 |> toRealArray) ∪ convex_hull(B2 |> toRealArray)) != 0 # Union of the convex hulls of the control points is non-empty
#        # B1 and B2 are a "candidate pair"
#        if diam(B1 ∪ B2) < ε
#            println("detected intersect between {} and {}", B1,B2)
#            #@show rdepth
#            return true
#        else # subdivides the curve with the larger diameter
#
#
#                B1_1 = [ B1[1:i](0.5) for i in 1:length(B1) ]
#                B1_2 = [ B1[1:i](1) for i in [length(B1)-i for i in 0:length(B1)-1]]
#                B2_1 = [ B2[1:i](0.5) for i in 1:length(B2) ]
#                B2_2 = [ B2[1:i](1) for i in [length(B2)-i for i in 0:length(B2)-1]]
##                return bezInt(B1_1,B2_1,rdepth+1) || bezInt(B1_1,B2_2,rdepth+1) || bezInt(B1_2,B2_1,rdepth+1) || bezInt(B1_2,B2_2,rdepth+1)
##                Return not only whether intersection is detected but control points of both curves up to intersect point.
#
#                (b::Bool,cps::Tuple{BezierCurve,BezierCurve}) =  bezInt(B1_1,B2_1,rdepth+1)
#
#                if b 
#                    return (b,cps)
#                end
#
#                (b::Bool,cps::Tuple{BezierCurve,BezierCurve}) =  bezInt(B1_1,B2_2,rdepth+1)
#                if b 
#                    return (b, append!(B2_1,B2_2))
#                end
#
#        end
#    else
#        # B1 and B2 are not "candidates" therefore, cannot intersect.
#        #@show "initial individuals are not candidates"
#        return false
#    end
#end
