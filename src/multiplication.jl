# compute the high-order half of a wide multiplication
mulhi(u::T, v::T) where T = (widemul(u, v) >> (sizeof(T)*8)) % T

# optimizations for 32-bit and 64-bit integers, avoiding resp. 64-bit and 128-bit arithmetic
@inline function mulhi(u::T, v::T) where T <: Union{Int32, UInt32}
    U = unsigned(T)
    u0 = (u & 0xFFFF)%U
    u1 = u >> 16
    v0 = (v & 0xFFFF)%U
    v1 = v >> 16
    w0 = u0*v0
    t = (u1*v0 + (w0 >> 16))%T
    w1 = t & 0xFFFF
    w2 = t >> 16
    w1 = (u0*v1 + w1)%T
    u1*v1 + w2 + (w1 >> 16)
end
@inline function mulhi(u::T, v::T) where T <: Union{Int64, UInt64}
    U = unsigned(T)
    u0 = (u & 0xFFFFFFFF)%U
    u1 = u >> 32
    v0 = (v & 0xFFFFFFFF)%U
    v1 = v >> 32
    w0 = u0*v0
    t = (u1*v0 + (w0 >> 32))%T
    w1 = t & 0xFFFFFFFF
    w2 = t >> 32
    w1 = (u0*v1 + w1)%T
    u1*v1 + w2 + (w1 >> 32)
end

# certain architectures have dedicated instructions for this, e.g., PTX mul.hi.
# TODO: can we write this code such that LLVM can pattern-match the correct instruction?
