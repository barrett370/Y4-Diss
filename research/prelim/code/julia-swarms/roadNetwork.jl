


##  A Road is defined using the Road coordinate system (X',Y') where Y' lim = width(road)


struct Road
    width:: Float32 # Width of road
    b2 :: Function# Function defining the bottom boundary of the road in cartesian space
    getY_ :: Function
    function Road(w,b2)
        getY(_x,x,y)= √((x-_x)^2 + (y-b2(_x))^2)/w
        new(w,b2,getY)
    end
end
