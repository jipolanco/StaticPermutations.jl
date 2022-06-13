"""
    PermutedDimsArray(A, perm::AbstractPermutation) -> B

Alternative `PermutedDimsArray` constructor taking a static permutation.

In contrast to the base constructors, the returned type is fully inferred here.
"""
function Base.PermutedDimsArray(
        A::AbstractArray{T,N}, perm::Permutation{p,N}) where {T,p,N}
    iperm = inv(perm)
    PermutedDimsArray{T, N, Tuple(perm), Tuple(iperm), typeof(A)}(A)
end

Base.PermutedDimsArray(A::AbstractArray, ::NoPermutation) =
    PermutedDimsArray(A, identity_permutation(A))
