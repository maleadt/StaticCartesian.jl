# StaticCartesian.jl

Proof-of-concept package exploring the advantages of statically-known Cartesian iterators.


## Motivation

Currently, indexing a `CartesianIndices` object with a linear index performs an integer
division:

```julia
julia> CartesianIndices((2, 3))

julia> @code_llvm debuginfo=:none Is[1]
```
```llvm
define void @julia_getindex_137([1 x [2 x i64]]* noalias nocapture sret([1 x [2 x i64]]) %0, [1 x [2 x [1 x i64]]]* nocapture nonnull readonly align 8 dereferenceable(16) %1, i64 signext %2) #0 {
top:
  ...
  %17 = add nsw i64 %2, -1
  %18 = udiv i64 %17, %7
  %19 = mul i64 %18, %7
  %20 = sub i64 %2, %19
  %21 = add nuw nsw i64 %18, 1
  ...
  ret void
}
```

On some platforms (notably GPUs) this is a very expensive operation. To avoid such
operations, this package provides the `StaticCartesianIndices` type that puts the iterator's
indices in the type domain so that they are known at compile time. This information can then
be used to avoid the integer division, as division by a constant can be expressed as a
series of bit operations:

```julia
julia> @code_llvm debuginfo=:none StaticCartesian.fast_fldmod(100, Val(7))
```
```llvm
define void @julia_fast_fldmod_300([2 x i64]* noalias nocapture sret([2 x i64]) %0, i64 signext %1) #0 {
top:
  ; mulhi
  %2 = and i64 %1, 4294967295
  %3 = ashr i64 %1, 32
  %4 = mul nuw nsw i64 %2, 613566757
  %5 = mul nsw i64 %3, 613566757
  %6 = lshr i64 %4, 32
  %7 = add nsw i64 %6, %5
  %8 = and i64 %7, 4294967295
  %9 = ashr i64 %7, 32
  %10 = mul nuw nsw i64 %2, 1227133513
  %11 = add nuw nsw i64 %8, %10
  %12 = mul nsw i64 %3, 1227133513
  %13 = lshr i64 %11, 32
  %14 = add nsw i64 %9, %12
  %15 = add nsw i64 %14, %13

  ; fldmod
  %16 = ashr i64 %15, 1
  %.lobit = lshr i64 %1, 63
  %value_phi = add nsw i64 %16, %.lobit
  %.neg = mul i64 %value_phi, -7
  %17 = add i64 %.neg, %1
  %.not = icmp eq i64 %17, 0
  %.not7 = icmp sgt i64 %1, -1
  %or.cond = or i1 %.not7, %.not
  %18 = add i64 %17, 7
  %value_phi1 = select i1 %or.cond, i64 %17, i64 %18
  %not.or.cond = xor i1 %or.cond, true
  %19 = sext i1 %not.or.cond to i64
  %value_phi2 = add nsw i64 %value_phi, %19
  %.sroa.0.0..sroa_idx = getelementptr inbounds [2 x i64], [2 x i64]* %0, i64 0, i64 0
  store i64 %value_phi2, i64* %.sroa.0.0..sroa_idx, align 8
  %.sroa.2.0..sroa_idx3 = getelementptr inbounds [2 x i64], [2 x i64]* %0, i64 0, i64 1
  store i64 %value_phi1, i64* %.sroa.2.0..sroa_idx3, align 8
  ret void
}
```

Ideally LLVM would be able to perform this operation, but it currently does not.

Note that much of the code above originates from the `mulhi` function, which computes the
upper bits of a wide multiplication. On some platforms (again, GPUs) this operation can be
performed using a single instuction, further reducing the cost of the division.


## Usage

```julia
using StaticCartesian

obj = rand(2, 2)    # whatever you want to index

function expensive_computation(obj, Is)
    i = rand(1:length(obj)) # get an actual index here, e.g., CUDA.threadIdx()
    I = Is[i]
    @inbounds obj[I]
end

# pass the iterator to the function so that it can get specialized
expensive_computation(obj, StaticCartesianIndices(obj))
```


## Acknowledgements

The implementation of integer-division-by-constant is based on the [Hacker's
Delight](https://en.wikipedia.org/wiki/Hacker%27s_Delight) book by Henry S. Warren, Jr.
