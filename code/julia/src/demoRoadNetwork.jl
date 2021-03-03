include("roadNetwork.jl")
import GraphPlot

b1(x) = 0
b2(x) = 12
road13 = Road(
    b1,
    b2,
    [],
    10
)
b1(x) = 0
b2(x) = 15
road31 =Road(
    b1,
    b2,
    [],
    10
)

b1(x) = 0
b2(x) = 12
road32 = Road(
    b1,
    b2,
    [],
    14
)

b1(x) = 0
b2(x) = 12
road23 = Road(
    b1,
    b2,
    [Rectangle(2,7,Point(4,1))],
    14
)

b1(x) = 0
b2(x) = 5
road43 = Road(
    b1,
    b2,
    [],
    12
)

b1(x) = 0
b2(x) = 15
road24 = Road(
    b1,
    b2,
    [],
    20
)

b1(x) = 0
b2(x) = 12
road25 = Road(
    b1,
    b2,
    [],
    10
)

b1(x) = 0
b2(x) = 12
road52 = Road(
    b1,
    b2,
    [],
    10
)

b1(x) = 0
b2(x) = 12
road45 = Road(
    b1,
    b2,
    [],
    7
)

b1(x) = 0
b2(x) = 12
road54 = Road(
    b1,
    b2,
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


GraphPlot.gplot(light_rn, edgelabel=edgelabel, nodelabel=nodelabel, linetype="curve")
