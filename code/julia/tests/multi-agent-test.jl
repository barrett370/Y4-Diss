include("../src/parallelCGA.jl")
import BenchmarkTools
import PlotlyJS

function multi_plot_benchmarks(benches, sf = true)

    means =
        map(ns -> map(b -> BenchmarkTools.mean(b).time * 10^-7, ns), benches[1])
    @show means
    @show mean_fitness = map(gen -> map(n -> mean(n), gen), benches[2])
    ns = vcat(1:length(benches[1][1]))
    ngens = vcat(1:length(benches[1]))
    @show ngens, ns, collect(Iterators.flatten(means))
    surf = PlotlyJS.surface(
        x = ns,
        y = ngens,
        z = means,
        surfacecolor = mean_fitness,
    )
    @show layout = PlotlyJS.Layout(;
        title = "Multi agent parallel planner, coloured by average fitness",
        xaxis_title = "Size of population",
        yaxis_title = "Number of generations",
        zaxis_title = "Time to plan /ms",
    )

    p = PlotlyJS.plot(surf, layout)
    p
end

function multi_test_gensPopsize(n = 20, n_gens = 10)
    starts = [Point(0, 5), Point(0, 8), Point(0, 6)]

    goals = [Point(20, 8), Point(18, 3), Point(15, 5)]


    b1(x) = 0
    b2(x) = 12
    l = 20
    obstacles = []
    road = Road(b1, b2, obstacles, l)
    res = [[] for i = 0:n_gens]
    plans = [[] for i = 0:n_gens]
    for ng = 0:n_gens
        for n = 1:n
            append!(plans[ng+1], [[]])
            "benchmarking with $ng generations over $n individuals" |> println
            append!(
                res[ng+1],
                [
                    BenchmarkTools.@benchmark append!(
                        $plans[$ng+1][$n],
                        [
                            PCGA(
                                $starts,
                                $goals,
                                $road,
                                n_gens = $ng,
                                n = $n,
                                selection_method = ranked,
                                mutation_method = gaussian,
                            ),
                        ],
                    )
                ],
            )
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
    (res, av_fs)
end
