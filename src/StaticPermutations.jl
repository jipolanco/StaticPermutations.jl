module StaticPermutations

export AbstractPermutation, Permutation, NoPermutation

export
    identity_permutation,
    isidentity,
    append,
    prepend

import Base: ==, *, /, \

include("types.jl")
include("operations.jl")
include("arrays.jl")

end
