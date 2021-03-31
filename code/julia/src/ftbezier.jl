include("bezier.jl")

function toFtArray(curve::BezierCurve)::Vector{Cdouble}
    nodes = []
    for p in curve
        append!(nodes,[p.x,p.y])
    end
    nodes = nodes |> Vector{Cdouble}
    nodes
end

function ft_bezLength(curve::BezierCurve)
    nodes = curve |> toFtArray
    #@show nodes = ([p.x for p in curve] ∪ [p.y for p in curve]) |> Vector{Cdouble}
    d = 2 |> Cint
    num_nodes = curve |> length |> Cint
    l  = 0 |> Cdouble |> Ref
    e = 0 |> Cint|> Ref
    "Making call to C method" |> println
    ccall(
        (:BEZ_compute_length, "/usr/local/lib/libbezier.so"),
        Cvoid,
        (Ref{Cint}, Ref{Cint}, Ref{Cdouble}, Ref{Cdouble}, Ref{Cint}),
        num_nodes,
        d,
        nodes,
        l,
        e,
    )
    @show e
    if e.x == 0
        return l
    else
        "Error" |> println
        return -1
    end
end

mutable struct Status
end

function ft_bezInt(B1::BezierCurve,B2::BezierCurve)

    n1 = B1|> length|>Cint |> Ref
    n2 = B2|> length|> Cint |> Ref
    nodes1 = B1 |> toFtArray
    nodes2 = B2 |> toFtArray
    intersects_size = Ref(Cint((B1|> length)*(B2|> length)*2))
    intersections = Vector{Cdouble}() |> Ref
    num_intersections = 0 |> Cint |> Ref
    coincident = false |> Ref

    status = 1 |> Cint |> Ref
    ccall(
        (:BEZ_curve_intersections, "/usr/local/lib/libbezier.so"),
        Cvoid,
        (Ref{Cint}, Ref{Cdouble}, Ref{Cint}, Ref{Cdouble},Ptr{Cint},Ref{Cdouble}, Ref{Cint},Ref{Bool},Ref{Cint}),

    n1,nodes1,
    n2,nodes2,
    intersects_size,
    intersections,
    num_intersections,
    coincident,
    status
    )



end
