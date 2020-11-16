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
    check_permutation(perm::AbstractPermutation)

Check the validity of a `Permutation`.

Throws `ArgumentError` if the permutation is invalid.

See also [`isperm`](@ref).

# Examples

```jldoctest; setup = :(import StaticPermutations: check_permutation)
julia> check_permutation(Permutation(3, 2, 1))  # no error

julia> check_permutation(NoPermutation())       # no error

julia> check_permutation(Permutation(3, 3, 1))
ERROR: ArgumentError: invalid permutation of dimensions: Permutation(3, 3, 1)
```
"""
function check_permutation(perm::AbstractPermutation)
    isperm(perm) && return
    throw(ArgumentError("invalid permutation of dimensions: $perm"))
end

"""
    permute(collection, perm::Permutation)

Permute collection according to the given permutation.

The collection may be a `Tuple` or a `CartesianIndex` to be reordered.

# Examples

```jldoctest
julia> perm = Permutation(2, 3, 1);

julia> permute((36, 42, 14), perm)
(42, 14, 36)

julia> permute(CartesianIndex(36, 42, 14), perm)
CartesianIndex(42, 14, 36)
```
"""
function permute end

@inline permute(t::Tuple, ::NoPermutation) = t
@inline function permute(t::Tuple{Vararg{Any,N}},
                         ::Permutation{perm,N}) where {N, perm}
    @inbounds ntuple(i -> t[perm[i]], Val(N))
end

@inline permute(I::CartesianIndex, perm) =
    CartesianIndex(permute(Tuple(I), perm))

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
Base.:*(p::Permutation, q::Permutation) = Permutation(permute(Tuple(q), p))
Base.:*(::NoPermutation, q) = q
Base.:*(p, ::NoPermutation) = p

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
function Base.:/(::Permutation{q,N}, ::Permutation{p,N}) where {p, q, N}
    if @generated
        perm = map(v -> findfirst(==(v), p)::Int, q)
        @assert permute(p, Permutation(perm)) === q
        :( Permutation($perm) )
    else
        perm = map(v -> findfirst(==(v), p)::Int, q)
        @assert permute(p, Permutation(perm)) === q
        Permutation(perm)
    end
end

Base.:/(y::AbstractPermutation, ::NoPermutation) = y

# In this case, the result is the inverse permutation of `x`, such that
# `permute(x, perm) == (1, 2, 3, ...)`.
Base.:/(::NoPermutation, x::Permutation{p,N}) where {p,N} =
    identity_permutation(Val(N)) / x

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

julia> t_perm = permute(t_orig, p)
(42, 14, 36)

julia> permute(t_perm, q) === t_orig
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
Base.:(==)(::Permutation{p}, ::Permutation{q}) where {p, q} = p === q
Base.:(==)(::NoPermutation, ::NoPermutation) = true
Base.:(==)(p::Permutation, ::NoPermutation) = isidentity(p)
Base.:(==)(np::NoPermutation, p::Permutation) = p == np

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
@deprecate permute_indices permute
@deprecate inverse_permutation inv
@deprecate prepend_to_permutation prepend
@deprecate append_to_permutation append
@deprecate(relative_permutation(x, y), y / x)
@deprecate(permute(p::Permutation, q::Permutation), q * p)
