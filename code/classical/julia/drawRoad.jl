
include("plottingUtils.jl")

# boundary1(x) = sin(0.3*x)
# boundary2(x) = sin(0.35*x)+4
boundary1(x) = 0 
boundary2(x) = 4
road = Road(
        boundary1,
        boundary2
)

start_point = Point(0,10)
goal_point = Point(19,9)


# Draw Road
road_graph = draw_road(road,0,20)
