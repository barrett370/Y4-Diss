include("../src/parallelCGA.jl")
import BenchmarkTools
import PlotlyJS

function multi_plot_benchmarks(benches, sf=true, zlims=nothing)

    means =
        map(ns -> map(b -> BenchmarkTools.mean(b).time * 10^-9, ns), benches[1])
    @show means
    mean_fitness = map(gen -> map(n -> mean(n), gen), benches[2])
    ns = vcat(1:length(benches[1][1]))
    ngens = vcat(1:length(benches[1]))
    @show ngens, ns, collect(Iterators.flatten(means))
    layout = PlotlyJS.Layout(;
        title="Multi agent parallel planner \n z=Planning time /s (left) | Average Fitness (right) | Planning time overlayed with Average Fitness",
        xaxis=attr(title="Size of population"),
        yaxis=attr(title="Number of generations"),
        zaxis=attr(title="Time to plan /ms"),
    )
    layout2 = PlotlyJS.Layout(;
        xaxis=attr(title="Size of population"),
        yaxis=attr(title="Number of generations"),
        zaxis=attr(title="Fitness (length of route)"),
    )
    surf = PlotlyJS.surface(
        x=ns,
        y=ngens,
        z=means,
        # surfacecolor = mean_fitness,
        layout=layout,
    )
    if zlims !== nothing
        mean_fitness = map(gen -> map(e -> begin
            if e > zlims[2]
                e = zlims[2]
            elseif e < zlims[1]
                e = zlims[1]
            else
                e
            end
        end, gen), mean_fitness)
    end

    surf2 = PlotlyJS.surface(
        x=ns,
        y=ngens,
        z=mean_fitness,
        zlims=(0, 60),
        # surfacecolor = means,
        layout=layout2,
    )
    p = PlotlyJS.plot(surf, layout)

    if sf
        savehtml(p, "images/tmp_multi-agent-result.html")
    end
    [p, PlotlyJS.plot(surf2, layout2)]

end

function multi_test_gensPopsize(n=20, n_gens=10; road_difficulty=1,samples=15)
    starts = [Point(0, 5), Point(0, 8), Point(0, 6)]

    goals = [Point(20, 8), Point(18, 3), Point(15, 5)]


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

    o3 =  Circle(1.85, Point(10, 5))
    b1_4(x) = 2cosh(0.1x) - 2
    b2_4(x) = 2cosh(0.12x) + 8
    road4 = Road(b1_4, b2_4, [o3], l)

    roads = [road1,road2,road3,road4]
    road = roads[road_difficulty]

    res = [[] for i = 0:n_gens]
    plans = [[] for i = 0:n_gens]

    if road_difficulty == 4
        starts = [Point(0, 5),Point(1, 3),Point(0, 7)]
        goals = [Point(18, 6),Point(16, 7),Point(20, 10)]
    end
    for ng = 0:n_gens
        for n = 1:n
            # global previous_checks = Dict{Tuple{BezierCurve,BezierCurve},Tuple{Bool,Tuple{BezierCurve,BezierCurve}}}()
            append!(plans[ng + 1], [[]])
            "benchmarking with $ng generations over $n individuals" |> println
            b = BenchmarkTools.@benchmarkable append!(
                        $plans[$ng + 1][$n],
                        [
                            PCGA(
                                $starts,
                                $goals,
                                $road,
                                true,
                                n_gens=$ng,
                                n=$n,
                                selection_method=ranked,
                                mutation_method=gaussian,
                            ),
                        ],
                    )
            b.params.samples = samples
            append!(
                res[ng + 1],
                [
                  run(b)  
                ],
            )
            @warn "clearing cache"
            previous_checks = Dict{Tuple{BezierCurve,BezierCurve},Tuple{Bool,Tuple{Real,Real}}}()
            @warn "cleared cache: $previous_checks"
        end
    end
    @show plans
    fs = map(
        gen -> map(n -> map(each -> map(p -> p.fitness, each), n), gen),
        plans,
    )
    av_fs = map(
        gen -> map(
            n -> [mean([i[j] for i in n]) for j = 1:length(starts)],
            gen,
        ),
        fs,
    )
    (res, av_fs, plans)
end

function multi_solution_complexity(benchmarks)
    solutions = benchmarks[3]
    ns = vcat(1:length(solutions[1]))
    ngens = vcat(1:length(solutions))
    avg_cps = map(gen -> map(n -> map(each -> each .|> getGenotype .|> length |> mean,n) |> mean, gen),solutions)
    layout = PlotlyJS.Layout(;
        title="Single agent planner z = avg. number of control points in generated routes",
        xaxis=attr(title="Size of population"),
        yaxis=attr(title="Number of generations"),
    )
    surf = PlotlyJS.surface(
        x=ns,
        y=ngens,
        z=avg_cps,
        layout=layout,
    )
    p = PlotlyJS.plot(surf, layout)
    [p]
end