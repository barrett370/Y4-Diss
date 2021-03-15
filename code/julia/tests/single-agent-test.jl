import BenchmarkTools
include("../src/GA.jl")
using PlotlyJS

function plot_benchmarks(benches, sf = true)

    means =
        map(ns -> map(b -> BenchmarkTools.mean(b).time * 10^-7, ns), benches[1])
    @show means
    @show mean_fitness = benches[2]
    ns = vcat(1:length(benches[1][1]))
    ngens = vcat(1:length(benches[1]))
    @show ngens, ns, collect(Iterators.flatten(means))
    surf = PlotlyJS.surface(
        x = ns,
        y = ngens,
        z = means,
        surfacecolor = mean_fitness
    )
    @show layout = Layout(;
        title = "Single agent planner, coloured by fitness",
        xaxis_title = "Size of population",
        yaxis_title = "Number of generations",
        zaxis_title = "Time to plan /ms"
    )

    Plotly.plot(surf, layout)

end

function test_gensPopsize(n = 20, n_gens = 10)
    start = Point(0, 5)
    goal = Point(20, 8)

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
                            GA(
                                $start,
                                $goal,
                                $road,
                                n_gens = $ng,
                                n = $n,
                            )[1].fitness,
                        ],
                    )
                ],
            )
        end
    end
    @show plans
    av_fitnesses = map(gen -> map(n -> mean(n), gen), plans)
    (res, av_fitnesses)
end


function save_res(res, dir)
    for gen in 1:length(res[1])
        for n in 1:length(res[1][gen])
            open("$dir/bench-$gen-$n", "w") do f
                println(f, BenchmarkTools.mean(res[1][gen][n]).time)
                println(f, res[2][gen][n])
            end
        end
    end
end
