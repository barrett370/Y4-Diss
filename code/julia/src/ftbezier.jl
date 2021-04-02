include("bezier.jl")

function toFtArray(curve::BezierCurve)::Vector{Cdouble}
    nodes = Vector{Cdouble}()
    for p in curve
        append!(nodes, [p.x, p.y])
    end
    nodes = nodes |> Vector{Cdouble}
    nodes
end

function ft_bezLength(curve::BezierCurve)
    nodes = curve |> toFtArray
    #@show nodes = ([p.x for p in curve] ∪ [p.y for p in curve]) |> Vector{Cdouble}
    d = 2 |> Cint
    num_nodes = curve |> length |> Cint
    l = 0 |> Cdouble |> Ref
    e = 0 |> Cint |> Ref
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

mutable struct Status end

function ft_bezInt(B1::BezierCurve, B2::BezierCurve)
    n1 = B1 |> length |> Cint
    n2 = B2 |> length |> Cint
    nodes1 = B1 |> toFtArray
    nodes2 = B2 |> toFtArray
    if (nodes1 == zeros(nodes1 |> length)) || (nodes2 == zeros(nodes2 |> length))
        @warn "returning false as one curve is default"
        return (false,([],[]))
    end
    #@show intersects_size= Cint((B1 |> length) * (B2 |> length))
    intersects_size= Cint(4)
    intersections = Vector{Cdouble}(zeros(4))
    num_intersections = 0 |> Cint |> Ref
    coincident = false |> Ref
    status = 1 |> Cint |> Ref


        @show n1
        @show nodes1
        @show n2
        @show nodes2
        @show intersects_size
        @show intersections
        @show num_intersections
        @show coincident
        @show status

    ccall(
        (:BEZ_curve_intersections, "/usr/local/lib/libbezier.so"),
        Cvoid,
        (
            Ref{Cint},
            Ref{Cdouble},
            Ref{Cint},
            Ref{Cdouble},
            Ref{Cint},
            Ref{Cdouble},
            Ref{Cint},
            Ref{Bool},
            Ref{Cint},
        ),
        n1,
        nodes1,
        n2,
        nodes2,
        intersects_size,
        intersections,
        num_intersections,
        coincident,
        status,
    )
    @warn status
    #intersections = filter(x -> x != 0.0, intersections)

    if num_intersections == 0
        return (false,([],[]))
    else
        b1_point = B1(intersections[1])
        b2_point = B2(intersections[2])
        return (true,(intersections[1],intersections[2]))
    end

end
