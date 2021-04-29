import BenchmarkTools
include("../src/GA.jl")
using PlotlyJS

function plot_benchmarks(benches, sf = true)

    means =
        map(ns -> map(b -> BenchmarkTools.mean(b).time * 10^-9, ns), benches[1])
    @show means
    @show mean_fitness = benches[2]
    ns = vcat(1:length(benches[1][1]))
    ngens = vcat(1:length(benches[1]))
    @show ngens, ns, collect(Iterators.flatten(means))
    layout = PlotlyJS.Layout(;
        title = "Singlew agent planner \n z=Planning time (left) /s | Average Fitness (right)",
        xaxis = attr(title = "Size of population"),
        yaxis = attr(title = "Number of generations"),
        zaxis = attr(title = "Time to plan /ms"),
    )
    layout2 = PlotlyJS.Layout(;
        xaxis = attr(title = "Size of population"),
        yaxis = attr(title = "Number of generations"),
        zaxis = attr(title = "Fitness (length of route)"),
    )
    surf = PlotlyJS.surface(
        x = ns,
        y = ngens,
        z = means,
        surfacecolor = mean_fitness,
        layout = layout,
    )
    surf2 = PlotlyJS.surface(
        x = ns,
        y = ngens,
        z = mean_fitness,
        surfacecolor = means,
        layout = layout2,
    )

    p = PlotlyJS.plot(surf, layout)
    [p, PlotlyJS.plot(surf2, layout2)]
end

function test_gensPopsize(n = 20, n_gens = 10; road_difficulty=1,samples=5)
    start = Point(0, 5)
    goal = Point(20, 8)

    b1(x) = 0
    b2(x) = 12
    l = 20
    obstacles = []
    road1 = Road(b1, b2, obstacles, l)

    o1 = Rectangle(1, 10, Point(3, 6))
    append!(obstacles, [o1])
    road2 = Road(b1, b2, obstacles, l)


    o2 = Rectangle(3, 10, Point(3, 4))
    append!(obstacles, [o2])
    road3 = Road(b1, b2, obstacles, l)

    o3 =  Circle(1.85,Point(10,5))
    b1_4(x) = 2cosh(0.1x)-2
    b2_4(x) = 2cosh(0.12x) +8
    road4 = Road(b1_4,b2_4, [o3], l)

    roads = [road1, road2, road3,road4]
    road = roads[road_difficulty]
    if road_difficulty == 4
        start = Point(0,5)
        goal = Point(18,6)
    end
    res = [[] for i = 0:n_gens]
    plans = [[] for i = 0:n_gens]
    for ng = 0:n_gens
        for n = 1:n
            append!(plans[ng+1], [[]])
            "benchmarking with $ng generations over $n individuals" |> println
            b = BenchmarkTools.@benchmarkable append!(
                        $plans[$ng+1][$n],
                        [
                            GA(
                                $start,
                                $goal,
                                $road,
                                n_gens = $ng,
                                n = $n,
                                selection_method = ranked,
                            )[1],
                        ],
                    )
                    b.params.samples=samples
                    @show b.params.samples
            append!(
                res[ng+1],
                [
                run(b)
                ],
            )
        end
    end

    @show plans
    fitnesses = map(gen -> map(n -> map(i -> i.fitness,n),gen),plans)
    av_fitnesses = map(gen -> map(n -> mean(n), gen), fitnesses)
    (res, av_fitnesses,plans)
end

function test_roadDifficulty()
    start = Point(0, 5)
    goal = Point(20, 8)


    plans = []
    ng = 5
    n = 7

    for road in roads
        "benchmarking for road $road" |> println
        BenchmarkTools.@benchmark append!(
            $plans,
            [
                GA(
                    $start,
                    $goal,
                    $road,
                    n_gens = $ng,
                    n = $n,
                    selection_method = ranked,
                )[1].fitness,
            ],
        )
    end
    @show plans
    av_fitnesses = map(gen -> map(n -> mean(n), gen), plans)
    (res, av_fitnesses)
end

function save_res(res, dir)
    for gen = 1:length(res[1])
        for n = 1:length(res[1][gen])
            open("$dir/bench-$gen-$n", "w") do f
                println(f, BenchmarkTools.mean(res[1][gen][n]).time)
                println(f, res[2][gen][n])
            end
        end
    end
end
