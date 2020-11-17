
include("plottingUtils.jl")
include("roadNetwork.jl")
# boundary1(x) = sin(0.3*x)
# boundary2(x) = sin(0.35*x)+4
boundary1(x) = 0
boundary2(x) = 4

o1 = Circle(2,Point(5,10))
o2 = Circle(0.6,Point(11,3))
start_point = Point(0, 10)
goal_point = Point(19, 9)
obstacles = [o1,o2]

road = Road(
        boundary1,
        boundary2,
        obstacles
)
# Draw Road
road_graph = draw_road(road, 0, 20)
