export StaticCartesianIndices

using Base.Cartesian: @nexprs, @ntuple

struct StaticCartesianIndices{N, I}
end

StaticCartesianIndices(iter::CartesianIndices{N}) where {N} =
    StaticCartesianIndices{N, iter.indices}()

StaticCartesianIndices(x) = StaticCartesianIndices(CartesianIndices(x))

# can only be linearly indexed
@inline @generated function Base.getindex(geniter::StaticCartesianIndices{N, Is},
                                          i::Int) where {N, Is}
    # TODO: handle more than just Base.OneTo
    sz = ntuple(i->Is[i].stop, N)

    quote
        rem_0 = i
        @nexprs $N j -> (rem_{j}, i_{j}) = fast_fldmod1(rem_{j-1}, Val($sz[j]))
        CartesianIndex(@ntuple $N i)
    end
end
