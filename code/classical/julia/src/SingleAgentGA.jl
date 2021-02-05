module SingleAgentGA
include("GA.jl")
include("utils.jl")

Base.@ccallable function julia_main()::Cint
    try
        real_main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

function real_main()

    boundary1(x) = 0
    boundary2(x) = 12
    o1 = Circle(2,Point(5,10))
    o2 = Circle(0.6,Point(11,3))
    obstacles = [o1,o2]

    road = Road(
            boundary1,
            boundary2,
            obstacles
    )
    @show ARGS
    start_pos_x = parse(Float64,ARGS[1])
    start_pos_y = parse(Float64,ARGS[2])
    end_pos_x = parse(Float64,ARGS[3])
    end_pos_y = parse(Float64,ARGS[4])
    n_gens = parse(Int64,ARGS[5])
    pop_size = parse(Int64,ARGS[6])
    P = "ERROR"
    if n_gens != ""
        if pop_size != ""
            P =GA(Point(start_pos_x,start_pos_y), Point(end_pos_x,end_pos_y),road,n_gens=n_gens,n=pop_size)
        else
            P=GA(Point(start_pos_x,start_pos_y), Point(end_pos_x,end_pos_y),road,n_gens=n_gens)
        end


    elseif pop_size != ""
            P=GA(Point(start_pos_x,start_pos_y), Point(end_pos_x,end_pos_y),road,n=pop_size)
    end

    @show P

end

if abspath(PROGRAM_FILE) == @__FILE__
    real_main()
end
end
