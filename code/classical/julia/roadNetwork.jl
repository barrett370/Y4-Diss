


##  A Road is defined using the Road coordinate system (X',Y') where Y' lim = width(road)

const Obstacle = Function


function circleShape(h,k,r)
    Θ = LinRange(0,2π,500)
    h .+ r*sin.(Θ), k.+ r*cos.(Θ)
end


struct Road
    boundary_1 :: Function
    boundary_2 :: Function
    Ỹ :: Function
    obstacles :: Array{Any}
    function Road(b1,b2,obs)
        Y = function Y(x,y)
            y_b1 = b1(x)
            y_b2 = b2(x)
            y_b1 + √((y-y_b1)^2) / √((y_b1-y_b2)^2)
        end
        new(b1,b2,Y,obs)
    end
end
