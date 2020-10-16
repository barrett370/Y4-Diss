

struct RN
    Nodes::Set{Char}
    Edges::Set{Tuple{Int64,Int64}}
end

exampleRoadNetwork = RN(
    Set(['A', 'B', 'C', 'D', 'a', 'b']),
    Set([(1, 5), (2, 5), (5, 6), (6, 3), (6, 4)]),
)
