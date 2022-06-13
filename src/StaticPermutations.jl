module StaticPermutations

export
    AbstractPermutation,
    Permutation,
    NoPermutation,
    PermutedArray

export
    identity_permutation,
    isidentity,
    append,
    prepend

import Base: ==, *, /, \

include("types.jl")
include("operations.jl")
include("permuteddimsarray.jl")
include("permutedarray.jl")

end
