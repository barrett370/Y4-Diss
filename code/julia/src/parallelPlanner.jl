include("parallelCGA.jl")


function getPathGroups(road_network::Graphs.GenericGraph, macroPaths)

    roads = Dict()
    map(
        e -> roads["e$(e.source)$(e.target)"] = e.attributes["road"],
        road_network.edges,
    )
    road_lengths = map(
        p -> map(
            i -> roads["e$(p[i])$(p[i + 1])"].length,
            collect(1:length(p) - 1),
        ),
        macroPaths,
    )
    runningTotalDistances = map(
        p -> append!([0], collect(map(i -> sum(p[1:i]), 1:length(p)))),
        road_lengths,
    )

    pathGroupings = Dict()
    for i = 1:length(macroPaths)
        @debug "checking for agent $(agents[i])"
        for j = 1:length(macroPaths[i]) - 1
            if (macroPaths[i][j], macroPaths[i][j + 1]) in pathGroupings |> keys
                @debug "already analysed $(pathGroupings[(macroPaths[i][j], macroPaths[i][j + 1])])"
                pre_plan = pathGroupings[(macroPaths[i][j], macroPaths[i][j + 1])]
            end

            # "checking for other plans going from $(macroPaths[i][j]) to $(macroPaths[i][j+1])  " |> println
            microPlanAgents = [i]
            for o = 1:length(macroPaths)
                if o != i
                    # "checking against agent $(agents[o])" |> println
                    if macroPaths[i][j] in macroPaths[o]# both routes pass through vertex at i,j at some point
                        @debug "routes pass same vertex ($(macroPaths[i][j])) at some point"
                        try
                            if macroPaths[i][j + 1] == macroPaths[o][findfirst(
                                x -> x == macroPaths[i][j],
                                macroPaths[o],
                            ) + 1] # both routes travel along same road at some point
                                road = filter(
                                    e ->
                                        e.source == macroPaths[i][j] &&
                                            e.target == macroPaths[i][j + 1],
                                    road_network.edges,
                                )[1]
                                @debug "routes $i, $o share an edge, $road, road: $(road.attributes["road"])"
                                if runningTotalDistances[i][j] +
                                   road.attributes["road"].length >
                                   runningTotalDistances[o][findfirst(
                                    x -> x == macroPaths[i][j],
                                    macroPaths[o],
                                )]
                                    @debug "agent $i and agent $o are on road $(road.attributes["road"]) at the same time"
                                    append!(microPlanAgents, o)
                                    # TODO why does 4 appear in its own plan and along with 4,1 ??
                                else
                                    @debug "agent $(agents[i]) leaves road, $road before $(agents[o]) enters, $microPlanAgents "
                                    # TODO how to handle this?
                                    microPlanAgents =
                                        append!(pre_plan, [microPlanAgents])[:]
                                end

                            end
                        catch e # TODO remove this, bad practice
                            # "routes do not share a road, $e" |> println
                        end
                    end
                end
            end
            @debug "(($(macroPaths[i][j]), $(macroPaths[i][j + 1])) ,$(microPlanAgents))"
            pathGroupings[(macroPaths[i][j], macroPaths[i][j + 1])] =
                [microPlanAgents]
        end

    end
    removeDupes(l) = map(
        i -> map(j -> filter!(e -> e ∉ l[i], l[j]), i - 1:-1:1),
        length(l):-1:2,
    )
    for key in pathGroupings |> keys
        if pathGroupings[key][1] == Int64
            @debug "not nested"
            groups = pathGroupings[key]
            removeDupes([groups])
            pathGroupings[key] = groups
        elseif pathGroupings[key][1][1] |> typeof != Int64
            @debug "nested"
            groups = pathGroupings[key][1]
            removeDupes(groups)
            pathGroupings[key] = groups
        end
    end
    pathGroupings
end


function planRoutes(
    agents::Array{Tuple{Int64,Int64}},
    road_network::Graphs.GenericGraph,
    multi_threaded=true,
)
    # Given a set of start and end goals on the macro road network, generate a series of sets of routes between roads.

    macroPaths = map(p -> macroPath(road_network, p[1], p[2]), agents)
    pathGroupings = getPathGroups(road_network, macroPaths)
    @debug pathGroupings

    prev_positions = zeros(length(agents))
    plans = []
    for agent in agents
        append!(plans, [[]])
    end
    plans

    for mp in macroPaths    # TODO make sure all routes being planned have their pre-requisites planned already.
        @debug "Planning macropath $mp"
        macroPath_plans = []
        for i = 1:length(mp) - 1
            microPath = (mp[i], mp[i + 1])
            @debug "plotting routes in $microPath"
            if microPath in keys(pathGroupings)
                # @async begin
                # TODO work out intial starting coordinates a better way
                # TODO work out goal coordinates a proper way
                parallel_agent_sets = pathGroupings[microPath]
                for parallel_agents in parallel_agent_sets
                    @debug parallel_agents
                    road = filter(
                        e ->
                            e.source == microPath[1] &&
                                e.target == microPath[2],
                        road_network.edges,
                    )[1].attributes["road"]
                    starts::Array{Point} = []
                    goals::Array{Point} = []
                    initial_road_width = pointDistance(
                        Point(0, road.boundary_2(0)),
                        Point(0, road.boundary_1(0)),
                    )
                    final_road_width = pointDistance(
                        Point(road.length, road.boundary_2(road.length)),
                        Point(road.length, road.boundary_1(road.length)),
                    )
                    initial_starts = 0
                    c = 0
                    for agent in parallel_agents
                        if prev_positions[agent] == 0 # Inital section of route, no known previous position
                            append!(
                                starts,
                                [
                                    Point(
                                        0,
                                        0.5 + (
                                            initial_starts * (
                                                initial_road_width /
                                                length(parallel_agents)
                                            )
                                        ),
                                    ),
                                ],
                            )
                            initial_starts = initial_starts + 1
                        else
                            append!(starts, [Point(0, prev_positions[agent])])
                        end
                        append!(
                            goals,
                            [
                                Point(
                                    road.length,
                                    1 + (
                                        c * (
                                            final_road_width /
                                            length(parallel_agents)
                                        )
                                    ),
                                ),
                            ],
                        )
                        c = c + 1
                    end

                    # @show starts,goals
                    # oldstd = stdout
                    # redirect_stdout(open("/dev/null","w"))
                    res = PCGA(
                        starts,
                        goals,
                        road,
                        multi_threaded,
                        n_gens=4,
                        n=12,
                        selection_method=roulette,
                        mutation_method=gaussian,
                    )
                    # redirect_stdout(oldstd)
                    @debug "Planned for this goalset"
                    for agent in parallel_agents
                        append!(
                            plans[agent],
                            [res[findfirst(x -> x == agent, parallel_agents)]],
                        )
                        prev_positions[agent] =
                            plans[agent][end].phenotype.goal.y
                    end
                    @debug "planned microPath $microPath, removing from pathGroupings"
                    filter!(s -> s != parallel_agents, pathGroupings[microPath])
                    # end
                end
            else
                @debug "microPath $microPath already planned"

            end

        end
    end
    plans
end

function plot_road_network(
    routes,
    rn::Graphs.GenericGraph,
    paths::Array{Tuple{Int64,Int64}},
)
    plots = []
    macroPaths = map(i -> macroPath(rn, i[1], i[2]), paths)
    pathGroups = getPathGroups(rn, macroPaths)
    c = 0
    for key in keys(pathGroups)
        @debug key
        road = filter(
            e -> e.source == key[1] && e.target == key[2],
            rn.edges,
        )[1].attributes["road"]
        @show road
        is::Array{Array{Individual}} = []
        j = 1
        for group in pathGroups[key]
        as = []
            @show group
            append!(is, [[]])
            
            for i in group
                route_section = findfirst(x -> x == key[1], macroPaths[i])
                @show route_section
                append!(is[j], [routes[i][route_section]])
                append!(as,[i])
            end
                r = draw_road(road, 0, road.length)
                plotGeneration!(r, is[j])
                plot!(r,title="e$(key[1])$(key[2])-agents($([ a for a in as]))")
                append!(
                plots,
                [r]
            )
            j += 1
        end

        c = c + 1
    end
    plots
end
