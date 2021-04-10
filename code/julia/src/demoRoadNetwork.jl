include("roadNetwork.jl")
import GraphPlot

road13_b1(x) = 0
road13_b2(x) = 12
road13 = Road(
    road13_b1,
    road13_b2,
    [],
    10
)
road31_b1(x) = 0
road31_b2(x) = 15
road31 =Road(
    road31_b1,
    road31_b2,
    [],
    10
)

road32_b1(x) = 0
road32_b2(x) = 12
road32 = Road(
    road32_b1,
    road32_b2,
    [],
    50
)

road23_b1(x) = 0
road23_b2(x) = 12
road23 = Road(
    road23_b1,
    road23_b2,
    [Rectangle(2,7,Point(4,1))],
    14
)

road43_b1(x) = 0
road43_b2(x) = 5
road43 = Road(
    road43_b1,
    road43_b2,
    [],
    12
)

road24_b1(x) = 0
road24_b2(x) = 15
road24 = Road(
    road24_b1,
    road24_b2,
    [],
    20
)

road25_b1(x) = 0
road25_b2(x) = 12
road25 = Road(
    road25_b1,
    road25_b2,
    [],
    10
)

road52_b1(x) = 0
road52_b2(x) = 12
road52 = Road(
    road52_b1,
    road52_b2,
    [],
    10
)

road45_b1(x) = 0
road45_b2(x) = 12
road45 = Road(
    road45_b1,
    road45_b2,
    [],
    7
)

road54_b1(x) = 0
road54_b2(x) = 12
road54 = Road(
    road54_b1,
    road54_b2,
    [],
    7
)
es = [
    (1,3,road13),
    (3,1,road31),
    (3,2,road32),
    (2,3,road23),
    (4,3,road43),
    (2,4,road24),
    (2,5,road25),
    (5,2,road52),
    (5,4,road54),
    (4,5,road45)
]

rn = createRoadGraph(5,es)
light_rn = rn |> graphToLightGraph

edgelabel = map(e -> "e$(e[1])$(e[2]): $(e[3])", LightGraphs.edges(light_rn).iter)
#edgelabel = map(e -> "e$(e.source)$(e.target)-$(e.attributes["road"].length))"", rn.edges)
nodelabel = vcat(1:LightGraphs.nv(light_rn))


gp = GraphPlot.gplot(light_rn, edgelabel=edgelabel, nodelabel=nodelabel, linetype="curve")
#GraphPlot.gplothtml(light_rn, edgelabel=edgelabel, nodelabel=nodelabel, linetype="curve")
