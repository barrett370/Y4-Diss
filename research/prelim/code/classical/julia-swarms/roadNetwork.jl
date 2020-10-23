


##  A Road is defined using the Road coordinate system (X',Y') where Y' lim = width(road)


struct Road
    width:: Float32 # Width of road
    b2# Function defining the bottom boundary of the road in cartesian space
    function getY(_x,x,y)
        √((x-_x)^2 + (y-b2(_x))^2)
    end
end

testRoad = Road(
    5.0,
    function b2(x) # function for straight bottom of a road
        0
    end
)
