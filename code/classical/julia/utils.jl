
struct Point
    x::Real
    y::Real
end

curry(f,x) = (xs...) -> f(x,xs...)
