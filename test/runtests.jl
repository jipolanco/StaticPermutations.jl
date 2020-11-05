using FastPermutations
using Test

@testset "FastPermutations.jl" begin
    perm = Permutation(2, 3, 1)
    noperm = NoPermutation()

    @testset "Constructors" begin
        @test perm === Permutation((2, 3, 1))
        @inferred (() -> Permutation(2, 3, 1))()
        @inferred (() -> Permutation((2, 3, 1)))()
        @inferred NoPermutation()
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
        @test is_valid_permutation(perm)
        @test is_valid_permutation(noperm)
        @test !is_valid_permutation(Permutation(2, 5, 3))

        @test_nowarn check_permutation(perm)
        @test_nowarn check_permutation(noperm)
        @test_throws ArgumentError check_permutation(Permutation(2, 5, 3))
    end

    iperm = inverse_permutation(perm)
    @testset "Inverse permutation" begin
        @inferred inverse_permutation(perm)
        @test iperm === inv(perm)
    end

    @testset "Identity permutation" begin
        @inferred identity_permutation(Val(4))
        id = identity_permutation(Val(4))
        @test id === Permutation(1, 2, 3, 4)
        @test is_identity_permutation(NoPermutation())
        @test is_identity_permutation(id)
        @test is_identity_permutation(permute_indices(perm, iperm))
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

    @testset "Permute indices" begin
        ind = (20, 30, 10)
        ind_perm = (30, 10, 20)
        @test permute_indices(ind, noperm) === ind
        @test permute_indices(ind, perm) === ind_perm
        @test permute_indices(CartesianIndex(ind), perm) === CartesianIndex(ind_perm)
        @inferred permute_indices(perm, iperm)
        @test permute_indices(perm, iperm) === Permutation(1, 2, 3)
    end

    @testset "Prepend / append" begin
        @inferred prepend_to_permutation(Permutation(2, 3, 1), Val(2))
        @inferred append_to_permutation(Permutation(2, 3, 1), Val(2))
        @test prepend_to_permutation(Permutation(2, 3, 1), Val(2)) ===
            Permutation(1, 2, 4, 5, 3)
        @test prepend_to_permutation(NoPermutation(), Val(2)) ===
            NoPermutation()
        @test append_to_permutation(Permutation(2, 3, 1), Val(2)) ===
            Permutation(2, 3, 1, 4, 5)
        @test append_to_permutation(NoPermutation(), Val(2)) ===
            NoPermutation()
    end
end
