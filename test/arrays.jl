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

    # Note that these call two different permutedims implementations.
    # For contiguous output, the definition is in Julia base (multidimensional.jl)
    @test permutedims!(dest_contiguous, src, perm) == v
    @test permutedims!(dest_strided, src, perm) == v

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
        @test sumdim(data, 1) == sumdim(x, 3)
        @test sum(data) == sum(x)
    end

    @testset "permutedims! (N = $N)" for N ∈ (3, 5)
        test_permutedims(Val(N))
    end
end
