


##  A Road is defined using the Road coordinate system (X',Y') where Y' lim = width(road)

const Obstacle = Function
    

struct Road
    boundary_1 :: Function
    boundary_2 :: Function
    Ỹ :: Function
    obstacles :: Array{Obstacle}
    function Road(b1,b2)
        Y = function Y(x,y)
            y_b1 = b1(x)
            y_b2 = b2(x)
            y_b1 + √((y-y_b1)^2) / √((y_b1-y_b2)^2)
        end
        new(b1,b2,Y,[])
    end
end
