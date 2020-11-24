"""
    Tuple(perm::Permutation)

Extract tuple representation of Permutation.

The result can be passed to `permutedims` and `PermutedDimsArray`.

Returns `nothing` if `perm` is a `NoPermutation`.

# Examples

```jldoctest
julia> Tuple(Permutation(3, 2, 1))
(3, 2, 1)

julia> Tuple(NoPermutation()) === nothing
true
```
"""
Base.Tuple(::Permutation{p}) where {p} = p
Base.Tuple(::NoPermutation) = nothing

"""
    length(perm::AbstractPermutation)

Returns length of permutation.

For `NoPermutation`, returns `nothing`.

# Examples

```jldoctest
julia> length(Permutation(3, 2, 1))
3

julia> length(NoPermutation()) === nothing
true
```
"""
Base.length(::Permutation{p}) where {p} = length(p)
Base.length(::NoPermutation) = nothing

"""
    isperm(perm::AbstractPermutation) -> Bool

Returns `true` if `perm` is a valid permutation, `false` otherwise.

The result is known at compile time.

# Examples

```jldoctest
julia> isperm(Permutation(3, 1, 2))
true

julia> isperm(Permutation(4, 1, 2))
false

julia> isperm(NoPermutation())
true
```
"""
Base.isperm(::NoPermutation) = true

function Base.isperm(::Permutation{P}) where {P}
    P :: Tuple
    if @generated
        # Call isperm tuple implementation in base Julia
        pp = isperm(P)
        :( $pp )
    else
        isperm(P)
    end
end

"""
    *(p::AbstractPermutation, collection)

Apply permutation to the given collection.

The collection may be a `Tuple` or a `CartesianIndex` to be reordered. If `p` is
a [`Permutation`](@ref), the collection must have the same length as `p`.

# Examples

```jldoctest
julia> p = Permutation(2, 3, 1);

julia> p * (36, 42, 14)
(42, 14, 36)

julia> p * CartesianIndex(36, 42, 14)
CartesianIndex(42, 14, 36)
```
"""
*(::NoPermutation, t::Tuple) = t

@inline function *(::Permutation{p,N}, t::Tuple{Vararg{Any,N}}) where {N,p}
    @inbounds ntuple(i -> t[p[i]], Val(N))
end

@inline *(p::AbstractPermutation, I::CartesianIndex) = CartesianIndex(p * Tuple(I))

"""
    *(p::AbstractPermutation, q::AbstractPermutation)

Compose two permutations: apply permutation `p` to permutation `q`.

Note that permutation composition is non-commutative.

# Examples

```jldoctest
julia> p = Permutation(2, 3, 1);

julia> q = Permutation(1, 3, 2);

julia> p * q
Permutation(3, 2, 1)

julia> q * p
Permutation(2, 1, 3)

julia> p * inv(p)
Permutation(1, 2, 3)

julia> inv(p) * p
Permutation(1, 2, 3)
```
"""
*(p::Permutation, q::Permutation) = Permutation(p * Tuple(q))
*(::NoPermutation, q::AbstractPermutation) = q
*(p::AbstractPermutation, ::NoPermutation) = p
*(p::NoPermutation, ::NoPermutation) = p

"""
    /(y::AbstractPermutation, x::AbstractPermutation)

Get relative permutation needed to get from `x` to `y`. That is, the permutation
`p` such that `p * x == y`.

# Examples

```jldoctest
julia> x = Permutation(3, 1, 2);

julia> y = Permutation(2, 1, 3);

julia> p = y / x
Permutation(3, 2, 1)

julia> p * x == y
true
```
"""
function /(::Permutation{q,N}, ::Permutation{p,N}) where {p, q, N}
    if @generated
        perm = map(v -> findfirst(==(v), p)::Int, q)
        @assert Permutation(perm) * p === q
        :( Permutation($perm) )
    else
        perm = map(v -> findfirst(==(v), p)::Int, q)
        @assert Permutation(perm) * p === q
        Permutation(perm)
    end
end

/(y::AbstractPermutation, ::NoPermutation) = y

# In this case, the result is the inverse permutation of `x`, such that
# `perm * x == (1, 2, 3, ...)`.
/(::NoPermutation, x::Permutation{p,N}) where {p,N} =
    identity_permutation(Val(N)) / x

"""
    \\(p::AbstractPermutation, x)

Undo permutation `p` from permuted collection `x`.

In other words, apply inverse of permutation `p` to `x`. This is effectively
equivalent to `inv(p) * x`.
"""
\(p::AbstractPermutation, x) = inv(p) * x

"""
    inv(p::Permutation)
    invperm(p::Permutation)

Returns the inverse permutation of `p`.

Functionally equivalent to Julia's `invperm`, with the advantage that the result
is a compile time constant.

See also [`/`](@ref).

# Examples

```jldoctest
julia> p = Permutation(2, 3, 1);

julia> q = inv(p)
Permutation(3, 1, 2)

julia> t_orig = (36, 42, 14);

julia> t_perm = p * t_orig
(42, 14, 36)

julia> q * t_perm === t_orig
true

```
"""
Base.inv(x::AbstractPermutation) = NoPermutation() / x
Base.invperm(x::AbstractPermutation) = inv(x)

"""
    identity_permutation(::Val{N})
    identity_permutation(A::AbstractArray{T,N})

Returns the identity permutation `Permutation(1, 2, ..., N)`.
"""
identity_permutation(::Val{N}) where {N} = Permutation(ntuple(identity, Val(N)))
identity_permutation(A::AbstractArray) = identity_permutation(Val(ndims(A)))

"""
    isidentity(p::Permutation)

Returns `true` if `p` is an identity permutation, i.e. if it is equivalent to
`(1, 2, 3, ...)`.

```jldoctest
julia> isidentity(Permutation(1, 2, 3))
true

julia> isidentity(Permutation(1, 3, 2))
false

julia> isidentity(NoPermutation())
true
```
"""
isidentity(::NoPermutation) = true

function isidentity(perm::Permutation)
    N = length(perm)
    perm === identity_permutation(Val(N))
end

# Comparisons: (1, 2, ..., N) is considered equal to NoPermutation, for any N.
==(::Permutation{p}, ::Permutation{q}) where {p,q} = p === q
==(::NoPermutation, ::NoPermutation) = true
==(p::Permutation, ::NoPermutation) = isidentity(p)
==(np::NoPermutation, p::Permutation) = p == np

"""
    append(p::Permutation, ::Val{M})

Append `M` non-permuted dimensions to the given permutation.

# Examples

```jldoctest
julia> append(Permutation(2, 3, 1), Val(2))
Permutation(2, 3, 1, 4, 5)

julia> append(NoPermutation(), Val(2))
NoPermutation()
```
"""
function append(::Permutation{p}, ::Val{M}) where {p, M}
    N = length(p)
    Permutation(p..., ntuple(i -> N + i, Val(M))...)
end

append(np::NoPermutation, ::Val) = np

"""
    prepend(p::Permutation, ::Val{M})

Prepend `M` non-permuted dimensions to the given permutation.

# Examples

```jldoctest
julia> prepend(Permutation(2, 3, 1), Val(2))
Permutation(1, 2, 4, 5, 3)

julia> prepend(NoPermutation(), Val(2))
NoPermutation()
```
"""
function prepend(::Permutation{p}, ::Val{M}) where {p, M}
    Permutation(ntuple(identity, Val(M))..., (M .+ p)...)
end

prepend(np::NoPermutation, ::Val) = np

@deprecate is_valid_permutation isperm
@deprecate is_identity_permutation isidentity
@deprecate inverse_permutation inv
@deprecate prepend_to_permutation prepend
@deprecate append_to_permutation append
@deprecate(relative_permutation(x, y), y / x)
@deprecate(permute_indices(p, q), q * p)
@deprecate(permute(p, q), q * p)
