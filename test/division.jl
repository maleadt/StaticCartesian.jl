using InteractiveUtils

@testset "division" begin

@testset for T in [Int32, Int64, UInt32, UInt64]

special_numbers = [1, 2, 3, typemax(T)-1, typemax(T)]
if T <: Signed
    append!(special_numbers, [typemin(T)+1, -3, -2, -1])
end

for n in special_numbers, d in special_numbers
    @test fldmod(n%T, d) == fast_fldmod(n%T, Val(d))
end

end # T

# bug in mulhi
@test fldmod(2^32-1, 2^32-1) == fast_fldmod(2^32-1, Val(2^32-1))

@testset "codegen" begin
for T in (Int32, UInt32)
    ir = sprint(io->code_llvm(io, fast_fldmod, (T, Val{7}); debuginfo=:none))
    @test !contains(ir, "div")
    @test !contains(ir, "i64")
end

for T in (Int64, UInt64)
    ir = sprint(io->code_llvm(io, fast_fldmod, (T, Val{7}); debuginfo=:none))
    @test !contains(ir, "div")
    @test !contains(ir, "i128")
end
end

end # division
