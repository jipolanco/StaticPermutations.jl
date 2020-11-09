# Alternative PermutedDimsArray constructors taking compile-time permutations.
# In contrast to the base constructors, the type of the returned array is fully
# inferred here.
function Base.PermutedDimsArray(
        A::AbstractArray{T,N}, perm::Permutation) where {T,N}
    iperm = inv(perm)
    PermutedDimsArray{T, N, Tuple(perm), Tuple(iperm), typeof(A)}(A)
end

Base.PermutedDimsArray(A::AbstractArray, ::NoPermutation) =
    PermutedDimsArray(A, identity_permutation(Val(ndims(A))))
