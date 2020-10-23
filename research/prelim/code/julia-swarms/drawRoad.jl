
using Plots


b2(x) = sin(0.2*x + 2.0 ) # function for straight bottom of a road
width = 5
testRoad = Road(
    width,
    b2
)


plot(b2,0,π/2)
# plot!(b1)
savefig("sin")
