@testset "magic numbers" begin

# Table 10-1
@testset "W=32" begin

@testset "signed" begin

# powers of 2
for k in 1:31
    d = big(2)^k
    M, s, a = StaticCartesian.signed_magic(32, d)
    @test M%UInt32 == 0x80000001
    @test s == k-1
end

# others
known_magic = (
    3   => (0x55555556, 0),
    5   => (0x66666667, 1),
    6   => (0x2AAAAAAB, 0),
    7   => (0x92492493, 2),
    9   => (0x38E38E39, 1),
    10  => (0x66666667, 2),
    11  => (0x2E8BA2E9, 1),
    12  => (0x2AAAAAAB, 1),
    25  => (0x51EB851F, 3),
    125 => (0x10624DD3, 3),
    625 => (0x68DB8BAD, 8),
)
for (d, (known_M, known_s)) in known_magic
    M, s, a = StaticCartesian.signed_magic(32, d)
    @test M%UInt32 == known_M
    @test s == known_s
end

end # signed

@testset "unsigned" begin

# powers of 2
for k in 1:31
    d = big(2)^k
    M, s, a = StaticCartesian.unsigned_magic(32, d)
    @test M%UInt32 == big(2)^(32-k)
    @test s == 0
end

# others
known_magic = (
    3   => (0xAAAAAAAB, 1, false),
    5   => (0xCCCCCCCD, 2, false),
    6   => (0xAAAAAAAB, 2, false),
    7   => (0x24924925, 3, true),
    9   => (0x38E38E39, 1, false),
    10  => (0xCCCCCCCD, 3, false),
    11  => (0xBA2E8BA3, 3, false),
    12  => (0xAAAAAAAB, 3, false),
    25  => (0x51EB851F, 3, false),
    125 => (0x10624DD3, 3, false),
    625 => (0xD1B71759, 9, false),
)
for (d, (known_M, known_s, known_a)) in known_magic
    M, s, a = StaticCartesian.unsigned_magic(32, d)
    @test M%UInt32 == known_M
    @test s == known_s
    @test a == known_a
end

end # unsigned

end # W=32

# Table 10-2
@testset "W=64" begin

@testset "signed" begin

# powers of 2
for k in 1:31
    d = big(2)^k
    M, s, a = StaticCartesian.signed_magic(64, d)
    @test M%UInt64 == 0x8000000000000001
    @test s == k-1
end

# others
known_magic = (
    3   => (0x5555555555555556, 0),
    5   => (0x6666666666666667, 1),
    6   => (0x2AAAAAAAAAAAAAAB, 0),
    7   => (0x4924924924924925, 1),
    9   => (0x1C71C71C71C71C72, 0),
    10  => (0x6666666666666667, 2),
    11  => (0x2E8BA2E8BA2E8BA3, 1),
    12  => (0x2AAAAAAAAAAAAAAB, 1),
    25  => (0xA3D70A3D70A3D70B, 4),
    125 => (0x20C49BA5E353F7CF, 4),
    625 => (0x346DC5D63886594B, 7),
)
for (d, (known_M, known_s)) in known_magic
    M, s, a = StaticCartesian.signed_magic(64, d)
    @test M%UInt64 == known_M
    @test s == known_s
end

end # signed

@testset "unsigned" begin

# powers of 2
for k in 1:31
    d = big(2)^k
    M, s, a = StaticCartesian.unsigned_magic(64, d)
    @test M%UInt64 == big(2)^(64-k)
    @test s == 0
    @test a == false
end

# others
known_magic = (
    3   => (0xAAAAAAAAAAAAAAAB, 1, false),
    5   => (0xCCCCCCCCCCCCCCCD, 2, false),
    6   => (0xAAAAAAAAAAAAAAAB, 2, false),
    7   => (0x2492492492492493, 3, true),
    9   => (0xE38E38E38E38E38F, 3, false),
    10  => (0xCCCCCCCCCCCCCCCD, 3, false),
    11  => (0x2E8BA2E8BA2E8BA3, 1, false),
    12  => (0xAAAAAAAAAAAAAAAB, 3, false),
    25  => (0x47AE147AE147AE15, 5, true),
    125 => (0x0624DD2F1A9FBE77, 7, true),
    625 => (0x346DC5D63886594B, 7, false),
)
for (d, (known_M, known_s, known_a)) in known_magic
    M, s, a = StaticCartesian.unsigned_magic(64, d)
    @test M%UInt64 == known_M
    @test s == known_s
    @test a == known_a
end

end # unsigned

end # W=64

end # magic numbers
