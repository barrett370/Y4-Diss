
function (curve::CuArray{Float64})(t::Float64)::Tuple{Float64,Float64}
    if curve|> length == 2
        (curve[1],curve[2])
    else
        b1 = curve[1:end-2]
        b2 = curve[3:end]
        return ((1-t).*b1(t) .+ (t.*b2(t)))
    end
end