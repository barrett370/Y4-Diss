
struct Point
    x::Real
    y::Real
    function Point(p::Tuple{Real,Real})
        new(p[1],p[2])
    end
    function Point(x::Real,y::Real)
        new(x,y)
    end
end

function convert(::Type{BezierCurve}, i::Individual)
  i.phenotype.genotype
end

curry(f,x) = (xs...) -> f(x,xs...)
