using InteractiveUtils

@testset "cartesian indices" begin

Is = CartesianIndices((100,200,300))
StaticIs = StaticCartesianIndices(Is)

for i in [1, 2, 99, 100, 101, 100*200-1, 100*200, 100*200+1, 100*200*300-1, 100*200*300]
    @test Is[i] == StaticIs[i]
end

# indexing the iterator normally does an integer division
ir = sprint(io->code_llvm(io, getindex, (typeof(Is), Int); debuginfo=:none))
@test contains(ir, "div")

ir = sprint(io->code_llvm(io, getindex, (typeof(StaticIs), Int); debuginfo=:none))
@test !contains(ir, "div")

end
