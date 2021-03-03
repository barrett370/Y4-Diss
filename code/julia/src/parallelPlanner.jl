include("parallelCGA.jl")

function planRoutes(agents::Array{Tuple{Int64,Int64}}, road_network::Graphs.GenericGraph)
    # Given a set of start and end goals on the macro road network, generate a series of sets of routes between roads.
    macroPaths = map(p -> macroPath(road_network, p[1],p[2]),agents)
    runningTotalDistances = map(p -> append!([0],collect(map(i -> sum(p[1:i]), 1:length(p)))), macroPaths)

    pathGroupings = Dict()
    for i in 1:length(macroPaths)
        "checking for agent $(agents[i])" |> println
        for j = 1:length(macroPaths[i])-1
            try pathGroupings[(macroPaths[i][j],macroPaths[i][j+1])]
                "already analysed" |> println
            catch e
                continue
            finally
                
                #"checking for other plans going from $(macroPaths[i][j]) to $(macroPaths[i][j+1])  " |> println
                microPlanAgents = [i]
                for o = 1:length(macroPaths)
                    if o != i
                        #"checking against agent $(agents[o])" |> println
                        if macroPaths[i][j] in macroPaths[o]# both routes pass through vertex at i,j at some point
                            #"routes pass same vertex ($(macroPaths[i][j])) at some point" |> println |> println
                            try
                                if macroPaths[i][j+1] == macroPaths[o][findfirst(x -> x==macroPaths[i][j],macroPaths[o])+1] # both routes travel along same road at some point
                                    road = filter(e -> e.source == macroPaths[i][j] && e.target == macroPaths[i][j+1], road_network.edges)[1]
                                    #"routes share an edge, $road, road: $(road.attributes["road"])" |> println
                                    if runningTotalDistances[i][j] + road.attributes["road"].length > runningTotalDistances[o][findfirst(x -> x==macroPaths[i][j], macroPaths[o])]
                                        #"agent $i and agent $o are on road $(road.attributes["road"]) at the same time" |> println
                                        append!(microPlanAgents,o)
                                    else
                                        #"agent $(agents[i]) leaves road before $(agents[o]) enters " |> println
                                    end

                                end
                            catch e
                            #"routes do not share a road, $e" |> println 
                            end
                        end
                    end
                end
                #"(($(macroPaths[i][j]), $(macroPaths[i][j+1])) ,$(microPlanAgents))" |> println
                pathGroupings[(macroPaths[i][j],macroPaths[i][j+1])] = microPlanAgents
            end
            
        end
    end
    

    @show pathGroupings

    prev_positions = zeros(length(agents))
    for macroPath in macroPaths
        @show macroPath
        for i in 1:length(macroPath)-1
            microPath = (macroPath[i],macroPath[i+1])
            if microPath in keys(pathGroupings)
                @async begin
                    "plotting routes in $microPath" |> println
                    # TODO work out intial starting coordinates a better way
                    # TODO work out goal coordinates a proper way
                    parallel_agents = pathGroupings[microPath]

                    road = filter(e -> e.source == microPath[1] && e.target == microPath[2], road_network.edges)[1].attributes["road"]
                    starts::Array{Point}=[]
                    goals::Array{Point} =[]
                    initial_road_width = pointDistance(Point(0,road.boundary_2(0)),Point(0, road.boundary_1(0)))
                    final_road_width = pointDistance(Point(road.length,road.boundary_2(road.length)),Point(road.length, road.boundary_1(road.length)))
                    initial_starts =0
                    c = 0
                    for agent in parallel_agents
                        if prev_positions[agent] == 0 #Inital section of route, no known previous position
                            append!(starts,[Point(0,0+(initial_starts*(initial_road_width/length(parallel_agents))))])
                            initial_starts = initial_starts +1
                        else
                            append!(starts,[prev_positions[agent]])
                        end
                        append!(goals,[Point(road.length,c*(final_road_width/length(parallel_agents)))])
                        c = c +1
                    end

                    @show starts,goals
                    @show res = PCGA(starts,goals,road,n_gens=0,n=1, selection_method="roulette",mutation_method="uniform")
                end
                
            else
                "microPath $microPath already planned" |> println
                
            end
        
        end
    end
    
end
