import BenchmarkTools
include("../src/GA.jl")

function test_gensPopsize()
    start = Point(0, 5)
    goal = Point(20, 8)

    b1(x) = 0
    b2(x) = 12
    l = 20
    obstacles = []
    road = Road(b1, b2, obstacles, l)
    res = [[] for i in 0:10]
    for ng = 0:10
        for n = 1:20
            "benchmarking with $ng generations over $n individuals" |> println
            append!(res[ng+1], [BenchmarkTools.@benchmark GA(
                $start,
                $goal,
                $road,
                n_gens = $ng,
                n = $n,
            )])
        end
    end
    res
end

function pretty(t)
    if length(t) > 0
        min = minimum(t)
        max = maximum(t)
        med = median(t)
        avg = mean(t)
        memorystr = string(BenchmarkTools.prettymemory(BenchmarkTools.memory(min)))
        allocsstr = string(BenchmarkTools.allocs(min))
        minstr = string(BenchmarkTools.prettytime(BenchmarkTools.time(min)), " (", BenchmarkTools.prettypercent(BenchmarkTools.gcratio(min)), " GC)")
        maxstr = string(BenchmarkTools.prettytime(BenchmarkTools.time(max)), " (", BenchmarkTools.prettypercent(BenchmarkTools.gcratio(max)), " GC)")
        medstr = string(BenchmarkTools.prettytime(BenchmarkTools.time(med)), " (", BenchmarkTools.prettypercent(BenchmarkTools.gcratio(med)), " GC)")
        meanstr = string(BenchmarkTools.prettytime(BenchmarkTools.time(avg)), " (", BenchmarkTools.prettypercent(BenchmarkTools.gcratio(avg)), " GC)")
    else
        memorystr = "N/A"
        allocsstr = "N/A"
        minstr = "N/A"
        maxstr = "N/A"
        medstr = "N/A"
        meanstr = "N/A"
    end
    println( "BenchmarkTools.Trial: ")
    println( "  memory estimate:  ", memorystr)
    println( "  allocs estimate:  ", allocsstr)
    println( "  --------------")
    println( "  minimum time:     ", minstr)
    println( "  median time:      ", medstr)
    println( "  mean time:        ", meanstr)
    println( "  maximum time:     ", maxstr)
    println( "  --------------")
    println( "  samples:          ", length(t))
    print("  evals/sample:     ", t.params.evals)
end
