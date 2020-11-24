# StaticPermutations

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jipolanco.github.io/StaticPermutations.jl/stable) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jipolanco.github.io/StaticPermutations.jl/dev) [![Build Status](https://github.com/jipolanco/StaticPermutations.jl/workflows/CI/badge.svg)](https://github.com/jipolanco/StaticPermutations.jl/actions) [![Coverage](https://codecov.io/gh/jipolanco/StaticPermutations.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/jipolanco/StaticPermutations.jl)

Tools for dealing with compile-time dimension permutations of Julia arrays.

This package defines a `Permutation` type describing a permutation of dimensions.
Permutations can be composed, inverted, applied to collections and reverted, among other operations.
All these operations have zero runtime cost, since they are performed using the static information encoded in the `Permutation` type.
See the [documentation](https://jipolanco.github.io/StaticPermutations.jl/dev) for a list of implemented methods.

## Quick start

```julia
julia> using StaticPermutations

julia> perm = Permutation(2, 3, 1)
Permutation(2, 3, 1)

julia> typeof(perm)
Permutation{(2, 3, 1),3}
```

Permutations can be inverted and composed.
The resulting permutation is always fully inferred.

```julia
julia> inv(perm)  # same as invperm(perm)
Permutation(3, 1, 2)

julia> q = Permutation(3, 2, 1);

# Composition is performed using the `*` operator.
julia> perm * q
Permutation(2, 1, 3)

# Note that composition is non-commutative.
julia> q * perm
Permutation(1, 3, 2)

```

Permutations are applied to collections using the `*` operator:

```julia
julia> x = (42, 12, 32)  # these may be array indices, for instance
(42, 12, 32)

julia> y = perm * x
(12, 32, 42)
```

Permutations may be reverted using the `\` operator:

```julia
julia> x′ = perm \ y  # same as inv(perm) * y
(42, 12, 32)

julia> x′ == x
true
```
