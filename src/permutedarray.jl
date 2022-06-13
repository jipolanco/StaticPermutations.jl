# Alternative to Julia's `PermutedDimsArray` implementing fast indexing and
# iteration utilities.
#
# We try to stay as close as possible to Julia's PermutedDimsArray implementation.
# In fact, this is basically the same code (as of Julia 1.8) with some minor
# modifications to take advantage of static permutations.

struct PermutedArray{
        T, N, Perm <: Permutation, AA <: AbstractArray,
    } <: AbstractArray{T, N}
    parent :: AA
end

@inline permutation(::Type{<:PermutedArray{T,N,P}}) where {T,N,P} = P()
@inline permutation(A::PermutedArray) = permutation(typeof(A))

"""
    PermutedArray(A, perm::Permutation) -> B

Given an AbstractArray `A`, create a view `B` such that the
dimensions appear to be permuted. Similar to `permutedims`, except
that no copying occurs (`B` shares storage with `A`).

# Examples
```jldoctest
julia> A = rand(3, 5, 4);

julia> B = PermutedArray(A, Permutation(3, 1, 2));

julia> size(B)
(4, 3, 5)

julia> B[3,1,2] == A[1,2,3]
true
```
"""
function PermutedArray(data::AbstractArray{T,N}, perm::Permutation) where {T,N}
    length(perm) == N || throw(ArgumentError(string(perm, " is not a valid permutation of dimensions 1:", N)))
    PermutedArray{T, N, typeof(perm), typeof(data)}(data)
end

Base.parent(A::PermutedArray) = A.parent

Base.size(A::PermutedArray{T,N,perm}) where {T,N,perm} = permutation(A) * size(parent(A))
Base.axes(A::PermutedArray{T,N,perm}) where {T,N,perm} = permutation(A) * axes(parent(A))

Base.similar(A::PermutedArray, T::Type, dims::Base.Dims) = similar(parent(A), T, dims)

Base.unsafe_convert(::Type{Ptr{T}}, A::PermutedArray{T}) where {T} = Base.unsafe_convert(Ptr{T}, parent(A))

# It's OK to return a pointer to the first element, and indeed quite
# useful for wrapping C routines that require a different storage
# order than used by Julia. But for an array with unconventional
# storage order, a linear offset is ambiguous---is it a memory offset
# or a linear index?
Base.pointer(A::PermutedArray, i::Integer) = throw(ArgumentError("pointer(A, i) is deliberately unsupported for PermutedArray"))

function Base.strides(A::PermutedArray{T,N,perm}) where {T,N,perm}
    s = strides(parent(A))
    permutation(A) * s
end
Base.elsize(::Type{<:PermutedArray{<:Any, <:Any, <:Any, P}}) where {P} = Base.elsize(P)

@inline function Base.getindex(A::PermutedArray{T,N}, I::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(A, I...)
    perm = permutation(A)
    @inbounds val = getindex(A.parent, (perm \ I)...)
    val
end

@inline function Base.setindex!(A::PermutedArray{T,N}, val, I::Vararg{Int,N}) where {T,N}
    @boundscheck checkbounds(A, I...)
    perm = permutation(A)
    @inbounds setindex!(A.parent, val, (perm \ I)...)
    val
end

# Call specialisation in Base / multidimensional.jl (avoids ambiguity)
function Base.permutedims!(
        dest::Array{T,N}, src::StridedArray{T,N}, perm::Permutation,
    ) where {T,N}
    permutedims!(dest, src, Tuple(perm))
end

Base.permutedims!(dest, src::AbstractArray, perm::Permutation) =
    _permutedims!(dest, src, perm)

function _permutedims!(dest, src::AbstractArray, perm::Permutation)
    Base.checkdims_perm(dest, src, Tuple(perm))
    P = PermutedArray(dest, inv(perm))
    _copy!(P, src)
    return dest
end

function Base.copyto!(dest::PermutedArray{T,N}, src::AbstractArray{T,N}) where {T,N}
    checkbounds(dest, axes(src)...)
    _copy!(dest, src)
end
Base.copyto!(dest::PermutedArray, src::AbstractArray) = _copy!(dest, src)

@generated function _find_first_permuted_src(
        ::Permutation{perm}, src::AbstractArray,
    ) where {perm}
    d = 0
    while d < ndims(src) && perm[d+1] == d+1
        d += 1
    end
    :($d)
end

@generated function _find_first_permuted_dest(
        ::Permutation{perm}, ::Val{d},
    ) where {perm, d}
    d1 = findfirst(isequal(d+1), perm)::Int  # first permuted dim of dest
    :($d1)
end

function _copy!(P::PermutedArray{T,N}, src) where {T,N}
    perm = permutation(P)
    # If dest/src are "close to dense," then it pays to be cache-friendly.
    # Determine the first permuted dimension
    # d+1 will hold the first permuted dimension of src
    d = _find_first_permuted_src(perm, src)
    if d == ndims(src)
        copyto!(parent(P), src) # it's not permuted
    else
        R1 = CartesianIndices(axes(src)[1:d])
        d1 = _find_first_permuted_dest(perm, Val(d))  # first permuted dim of dest
        R2 = CartesianIndices(axes(src)[d+2:d1-1])
        R3 = CartesianIndices(axes(src)[d1+1:end])
        _permutedims!(P, src, R1, R2, R3, d+1, d1)
    end
    return P
end

@noinline function _permutedims!(P::PermutedArray, src, R1::CartesianIndices{0}, R2, R3, ds, dp)
    ip, is = axes(src, dp), axes(src, ds)
    for jo in first(ip):8:last(ip), io in first(is):8:last(is)
        for I3 in R3, I2 in R2
            for j in jo:min(jo+7, last(ip))
                for i in io:min(io+7, last(is))
                    @inbounds P[i, I2, j, I3] = src[i, I2, j, I3]
                end
            end
        end
    end
    P
end

@noinline function _permutedims!(P::PermutedArray, src, R1, R2, R3, ds, dp)
    ip, is = axes(src, dp), axes(src, ds)
    for jo in first(ip):8:last(ip), io in first(is):8:last(is)
        for I3 in R3, I2 in R2
            for j in jo:min(jo+7, last(ip))
                for i in io:min(io+7, last(is))
                    for I1 in R1
                        @inbounds P[I1, i, I2, j, I3] = src[I1, i, I2, j, I3]
                    end
                end
            end
        end
    end
    P
end

# Called e.g. by sum(A)
function Base._mapreduce_dim(f, op, init::Base._InitialValue, A::PermutedArray, dims::Colon)
    Base._mapreduce_dim(f, op, init, parent(A), dims)
end

# Called e.g. by sum(A; dims = 2)
function Base.mapreducedim!(f, op, B::AbstractArray{T,N}, A::PermutedArray{T,N}) where {T,N}
    C = PermutedArray(B, inv(permutation(A))) # make the inverse permutation for the output
    Base.mapreducedim!(f, op, C, parent(A))
    B
end

function Base.showarg(io::IO, A::PermutedArray{T,N}, toplevel) where {T,N}
    perm = permutation(A)
    print(io, "PermutedArray(")
    Base.showarg(io, parent(A), false)
    print(io, ", ", perm, ')')
    toplevel && print(io, " with eltype ", eltype(A))
    return nothing
end
