"""
    AbstractPermutation

Abstract type representing a compile-time permutation.

Subtypes are [`Permutation`](@ref) and [`NoPermutation`](@ref).
"""
abstract type AbstractPermutation end

"""
    Permutation{p} <: AbstractPermutation

Describes a compile-time dimension permutation.

The type parameter `p` should be a valid permutation such as `(3, 1, 2)`.

---

    Permutation(perm::Vararg{Int})
    Permutation(perm::NTuple{N,Int})

Constructs a `Permutation`.

# Example

Both are equivalent:

```julia
p1 = Permutation(2, 3, 1)
p2 = Permutation((2, 3, 1))
```
"""
struct Permutation{p,N} <: AbstractPermutation
    @inline function Permutation{p,N}() where {p,N}
        p::Dims{N}  # check compatibility
        new{p,N}()
    end
end

@inline Permutation(perm::Vararg{Int}) = Permutation{perm, length(perm)}()
@inline Permutation(perm::Tuple) = Permutation(perm...)

@inline Base.getindex(::Permutation{p}, ::Val{i}) where {p,i} = p[i]
@inline Base.getindex(p::Permutation, i::Integer) = p[Val(i)]

Base.show(io::IO, ::Permutation{p}) where {p} = print(io, "Permutation", p)

"""
    NoPermutation <: AbstractPermutation

Represents an identity permutation.

It is functionally equivalent to `Permutation(1, 2, 3, ...)`, and is included
for convenience.
"""
struct NoPermutation <: AbstractPermutation end

@inline Base.getindex(::NoPermutation, ::Val{i}) where {i} = i
@inline Base.getindex(::NoPermutation, i::Integer) = i

Base.show(io::IO, ::NoPermutation) = print(io, "NoPermutation()")
