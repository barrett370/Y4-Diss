include("roadNetwork.jl")
include("parallelCGA.jl")
global CACHE = true
global BEZPLOT=false
global previous_checks = Dict{Tuple{BezierCurve,BezierCurve},Tuple{Bool,Tuple{Real,Real}}}()
include("GA.jl")
boundary1(x) = 0
boundary2(x) = 12

o1 = Circle(2,Point(5,10))
o2 = Circle(0.6,Point(11,3))
start_point = Point(0, 10)
goal_point = Point(19, 9)
obstacles = [o1,o2]

road = Road(
        boundary1,
        boundary2,
        obstacles,
        20
)

starts = [Point(0,2),Point(0,6), Point(0,1)]
goals =  [Point(15,6.8),Point(15.1,4),Point(12,10)]
