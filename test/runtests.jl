using StaticPermutations

using Test

@testset "StaticPermutations.jl" begin
    perm = Permutation(2, 3, 1)
    noperm = NoPermutation()

    @testset "Constructors" begin
        @test perm === Permutation((2, 3, 1))
        @inferred (() -> Permutation(2, 3, 1))()
        @inferred (() -> Permutation((2, 3, 1)))()
        @inferred NoPermutation()
    end

    @testset "getindex!" begin
        @test perm[2] == perm[Val(2)] == 3
        @test noperm[2] == noperm[Val(2)] == 2
        valgettwo(p) = Val(p[2])
        @inferred valgettwo(perm)
        @inferred valgettwo(noperm)
    end

    @testset "I/O" begin
        @test string(perm) == "Permutation(2, 3, 1)"
        @test string(noperm) == "NoPermutation()"
    end

    @testset "Base operations" begin
        @test Tuple(perm) === (2, 3, 1)
        @test Tuple(noperm) === nothing

        @test length(perm) === 3
        @test length(noperm) === nothing
    end

    @testset "Permutation checks" begin
        @test isperm(perm)
        @test isperm(noperm)
        @test !isperm(Permutation(2, 5, 3))

        # Check that result is fully inferred
        ispermval(p) = Val(isperm(p))
        @inferred ispermval(perm)
        @inferred ispermval(noperm)
        @inferred ispermval(Permutation(2, 5, 3))
    end

    @testset "Composition" begin
        p = Permutation(2, 3, 1)
        q = Permutation(1, 3, 2)
        @inferred p * q
        @inferred p * NoPermutation()
        @inferred NoPermutation() * p
        @test p * q === Permutation(3, 2, 1)
        @test q === p \ Permutation(3, 2, 1)
        @test q * p === Permutation(2, 1, 3)
        @test p === q \ Permutation(2, 1, 3)
        @test p * NoPermutation() === p
        @test NoPermutation() * p === p
        @test NoPermutation() * NoPermutation() === NoPermutation()
        @test p * inv(p) == NoPermutation()
        @test inv(p) * p == NoPermutation()
    end

    iperm = inv(perm)
    @testset "Inverse permutation" begin
        @test perm * iperm == NoPermutation()
        @test iperm * perm == NoPermutation()
        @test invperm(perm) === iperm
        @inferred inv(perm)
    end

    @testset "Identity permutation" begin
        @inferred identity_permutation(Val(4))
        id = identity_permutation(Val(4))
        @test id === Permutation(1, 2, 3, 4)
        @test id == NoPermutation()  # they're functionally equivalent
        idval(p) = Val(isidentity(p))
        @test (@inferred idval(perm)) === Val(false)
        @test (@inferred idval(noperm)) === Val(true)
        @test (@inferred idval(id)) === Val(true)
        @inferred idval(perm)
        @test !isidentity(perm)
        @test isidentity(NoPermutation())
        @test isidentity(id)
        @test isidentity(perm * iperm)
    end

    @testset "Left division operator" begin
        a = Permutation(2, 3, 1, 4)
        b = Permutation(3, 1, 4, 2)
        @inferred b / a
        r = b / a
        @test r * a == b
        np = NoPermutation()
        @test a / np === a
        @test np / a === inv(a)
        @test np / np === np
    end

    @testset "Comparisons" begin
        @test Permutation(1, 3, 2) == Permutation(1, 3, 2)
        @test Permutation(1, 3, 2) != Permutation(3, 1, 2)
        @test Permutation(2, 1, 3) != Permutation(2, 1)
        @test Permutation(1, 2, 3) == NoPermutation()
        @test NoPermutation() == Permutation(1, 2, 3)
        @test Permutation(1, 3, 2) != NoPermutation()
        @test NoPermutation() == NoPermutation()
    end

    @testset "Apply permutations" begin
        ind = (20, 30, 10)
        ind_perm = (30, 10, 20)
        permval(perm) = Val(perm * (:aaa, :bbb, :ccc))
        @inferred permval(perm)
        @inferred permval(iperm)
        @inferred permval(noperm)
        @test noperm * ind === ind
        @test ind === noperm \ ind
        @test perm * ind === ind_perm
        @test ind === perm \ ind_perm
        @test perm * CartesianIndex(ind) === CartesianIndex(ind_perm)
        @test noperm * CartesianIndex(ind) === CartesianIndex(ind)
    end

    @testset "Prepend / append" begin
        @inferred prepend(Permutation(2, 3, 1), Val(2))
        @inferred append(Permutation(2, 3, 1), Val(2))
        @test prepend(Permutation(2, 3, 1), Val(2)) === Permutation(1, 2, 4, 5, 3)
        @test prepend(NoPermutation(), Val(2)) === NoPermutation()
        @test append(Permutation(2, 3, 1), Val(2)) === Permutation(2, 3, 1, 4, 5)
        @test append(NoPermutation(), Val(2)) === NoPermutation()
    end

    @testset "PermutedDimsArray" begin
        x = rand(3, 5, 4)
        @inferred PermutedDimsArray(x, perm)
        @inferred PermutedDimsArray(x, noperm)

        # Compare new and original constructors
        @test PermutedDimsArray(x, perm) === PermutedDimsArray(x, Tuple(perm))
        @test PermutedDimsArray(x, noperm) === PermutedDimsArray(x, (1, 2, 3))
    end

    include("arrays.jl")
end
