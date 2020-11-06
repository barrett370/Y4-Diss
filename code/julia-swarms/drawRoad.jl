
using Plots; gr
theme(:dark)

b2(x) = sin(x + 2.0)
b1(x) = b2(x) + 5 
width = 5
testRoad = Road(
    width,
    b2
)


plot(b2,0,π)
savefig("sin1")
plot!(b1,0,π)
savefig("sin")
