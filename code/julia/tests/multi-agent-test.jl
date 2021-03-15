include("../src/parallelCGA.jl")

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
                                selection_method = "ranked",
                                mutation_method = "gaussian",
                            )
                        ],
                    )
                ],
            )
        end
    end
    @show plans
    fs = map( gen -> map( n -> map(each -> map(p -> p.fitness, each), n), gen), plans)
    av_fs = map(gen -> map(n -> [mean([i[j] for i in n]) for j in 1:length(starts)], gen), fs)
    (res, av_fs)
end
