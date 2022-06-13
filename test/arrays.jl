using Random

function test_permutedims(::Val{N}) where {N}
    if N == 3
        perm = Permutation(3, 1, 2)
    elseif N == 5
        perm = Permutation(1, 4, 2, 3, 5)
    end

    dims_in = ntuple(d -> 2 + d, Val(N))
    dims_out = perm * dims_in

    src = rand(dims_in...)
    v = PermutedArray(src, perm)

    dest_contiguous = similar(src, dims_out)
    dest_strided = let x = similar(src, 2 .* dims_out)
        view(x, ntuple(d -> axes(x, d)[2:2:end], Val(N))...)
    end

    # Note that these call two different permutedims! implementations.
    # For contiguous output, the definition is in Julia base (multidimensional.jl)
    # We first check for allocations.
    # Since everything is inferred, there should be no allocations!
    precompile(permutedims, map(typeof, (dest_contiguous, src, perm)))
    precompile(permutedims, map(typeof, (dest_strided, src, perm)))
    @test 0 == @allocated permutedims!(dest_contiguous, src, perm)
    @test 0 == @allocated permutedims!(dest_strided, src, perm)

    @test dest_contiguous == v
    @test dest_strided == v

    let x = similar(src, 2 .* size(src))
        # This just calls copyto!
        local dest = view(x, ntuple(d -> axes(x, d)[2:2:end], Val(N))...)
        @test permutedims!(dest, src, identity_permutation(src)) == src
    end

    nothing
end

@testset "PermutedArray" begin
    Random.seed!(42)

    perm = Permutation(2, 3, 1)
    @assert inv(perm) != perm

    data = rand(3, 4, 5)
    u = @inferred PermutedDimsArray(data, perm)
    @assert u === PermutedDimsArray(data, Tuple(perm))

    v = @inferred PermutedArray(data, perm)
    @test match(
        r"^[\d,×]+ PermutedArray(.*) with eltype Float64",
        summary(v),
    ) !== nothing

    sumdim(x, d) = dropdims(sum(x, dims = d), dims = d)

    # Check that the behaviour is the same for PermutedDimsArray and for PermutedArray.
    @testset "Type: $(nameof(typeof(x)))" for x ∈ (u, v)
        @test size(x) === perm * size(data)
        @test axes(x) === perm * axes(data)
        @test typeof(similar(x)) === typeof(data)
        @test size(similar(x)) === size(x)
        @test_throws ArgumentError pointer(x, 1)
        @test Base.unsafe_convert(Ptr{Float64}, x) === pointer(data)
        @test strides(x) === perm * strides(data)
        @test Base.elsize(typeof(x)) === Base.elsize(typeof(data))
        # This depends on the specific permutation...
        # It's used to test Base._mapreduce_dim
        @test sumdim(data, 1) ≈ sumdim(x, 3)
        @test sum(data) ≈ sum(x)
    end

    @testset "copyto!" begin
        dest = PermutedArray(similar(data, Float32), perm)
        varr = Array(v)
        @test copyto!(dest, varr) ≈ v
        @test copyto!(dest, Float32.(varr)) ≈ v
    end

    @testset "permutedims! (N = $N)" for N ∈ (3, 5)
        test_permutedims(Val(N))
    end
end
