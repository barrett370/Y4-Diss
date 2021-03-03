
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


curry(f,x) = (xs...) -> f(x,xs...)

pointDistance(p1,p2) = √((p1.x-p2.x)^2 + (p1.y-p2.y)^2)
