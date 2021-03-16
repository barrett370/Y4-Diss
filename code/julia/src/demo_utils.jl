include("GA.jl")


function sa_demo()
    b1(x) = 0
    b2(x) = 10

    start_point = Point(0, 5)
    goal_point = Point(15, 8)

    o1 = Circle(1, Point(15, 5))
    o2 = Circle(1.2, Point(2.5, 7))
    o3 = Circle(0.8, Point(7, 6))
    o4 = Circle(0.8, Point(12, 2))
    l = 20
    road = Road(b1, b2, [o1, o2, o3, o4], l)

    road_plt = draw_road(road, 0, l)
    scatter!(
        road_plt,
        [(start_point.x, start_point.y), (goal_point.x, goal_point.y)],
    )
    P = GA(
        start_point,
        goal_point,
        road,
        n_gens = 3,
        n = 5,
        selection_method = "roulette",
    )
    plotGeneration!(road_plt, P)
end


function ma_demo()

    starts = [Point(0, 5), Point(0, 8), Point(0, 6)]

    goals = [Point(20, 8), Point(18, 3), Point(15, 5)]


    b1(x) = 0
    b2(x) = 12
    l = 20
    obstacles = []
    road = Road(b1, b2, obstacles, l)
    n=6
    ng=2

    road_plt = draw_road(road, 0, l)
    P = PCGA(
        starts,
        goals,
        road,
        n_gens = ng,
        n = n,
        selection_method = "roulette",
        mutation_method = "gaussian",
    )


end
