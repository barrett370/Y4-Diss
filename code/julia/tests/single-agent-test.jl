import BenchmarkTools
include("../src/GA.jl")
using Plots;

function plot_benchmarks(benches, sf = true)

    means =
        map(ns -> map(b -> BenchmarkTools.mean(b).time * 10^-7, ns), benches[1])
        @show means
    mean_times = benches[2]
    ns = vcat(1:length(benches[1][1]))
    ngens = vcat(1:length(benches[1]))

    new_ns = []
    new_ngens = []
    new_means = []
    new_mean_times = []
    for ng in ngens
        for n in ns
            append!(new_ns, n)
            append!(new_ngens, ng)
            append!(new_means, means[ng][n])
            append!(new_mean_times, mean_times[ng][n])
        end
    end

    #p = plot(new_ngens, new_ns, new_means, seriestype = :scatter ,zaxis="Time to plan /ms",leg=false)
    #plot!(p, new_ngens,new_ns,new_means, seriestype=:surface)
    @show size(new_means)
    @show size(new_ns) ==
          size(new_ngens) ==
          size(new_means) ==
          size(new_mean_times)
          @show typeof(new_mean_times)
          @show new_mean_times
         @show new_means
    p = plot(
        new_ngens,
        new_ns,
        new_means,
        #c = cgrad([:orange, :blue], new_mean_times),
        fill_z = new_mean_times,
        seriestype = :surface,
        zaxis = "Time to plan /ms",
    )
    plot!(p, new_ngens,new_ns,new_means, seriestype=:scatter,leg=false)
    xaxis!("Number of generations")
    yaxis!("Size of population")
    @show size(mean_times,1)
    @show size(mean_times,2)
    @show typeof(mean_times)
    hm = Plots.heatmap(vcat(1:size(mean_times,1)), vcat(1:size(mean_times,2)),mean_times)
    @show maximum(new_means)
    @show maximum(new_mean_times)
    #p= surface(new_ngens,new_ns, new_means, c = cgrad([:, :orange],))
    xaxis!("Number of generations")
    yaxis!("Size of population")
    #pgfplots()
    #Plots.savefig(p,"images/single-agent-result.tikz")
    if sf
        Plots.savefig(p, "images/single-agent-result02.png")
    end

    plot(p,hm)


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
    #av_fitnesses = map(ng -> map(fs -> mean(fs), ng), plans)
    av_fitnesses = map(gen -> map(n -> mean(n), gen), plans)
    (res, av_fitnesses)
end
