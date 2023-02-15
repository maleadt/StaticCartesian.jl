export fast_fldmod, fast_fldmod1

#
# division
#

# inputs:
#   n: dividend
#   d: divisor
# outputs:
#   M: magic number
#   s: shift amount
#   a: "add" indicator

# TODO: special-case powers of 2

## signed

signed_magic(W, d) = signed_magic(big(W), big(d))
function signed_magic(W::BigInt, d::BigInt)
    # section 10-4
    @assert W >= 3
    @assert 2 <= d <= 2^(W-1)

    n_c = 2^(W-1) - rem(2^(W-1), d) - 1

    # find least p and m
    for p in W:2*W
        # shift amount
        s = p - W

        if 2^p > n_c * (d - rem(2^p, d))        # (6)
            m = (2^p + d - rem(2^p, d)) ÷ d     # (5)

            # reinterpret the magic number as a signed integer
            M, a = if 0 <= m <= 2^(W-1)
                m, false
            else
                # need to truncate, so we'll have to adapt the generated code
                m - 2^W, true
            end
            return (; M, s, a)
        end
    end
    error("Can't find p, something is wrong.")
end

function emit_fast_div(n::Symbol, T::Type{<:Signed}, d::Integer)
    W = big(sizeof(T)*8)

    # corner cases and negative divisors should have been handled already
    @assert d >= 2

    # find least p and m
    M, s, a = signed_magic(W, d)

    quote
        # calculate the quotient based on the multiplier and shift amount
        q = mulhi(n, $(M%T))
        if $a
            q += n
        end
        q >>= $(T(s))
        if n < 0
            q += one(T)
        end
        q
    end
end

## unsigned

unsigned_magic(W, d) = unsigned_magic(big(W), big(d))
function unsigned_magic(W::BigInt, d::BigInt)
    # section 10-9
    @assert W >= 1
    @assert 1 <= d <= 2^W

    n_c = 2^W - rem(2^W, d) - 1

    # find least p and m
    for p in W:2*W
        # shift amount
        s = p - W

        if 2^p > n_c * (d - 1 - rem(2^p - 1, d))    # (27)
            m = (2^p + d - 1 - rem(2^p - 1, d)) ÷ d # (26)

            # reinterpret the magic number as a signed integer
            M, a = if 0 <= m <= 2^W
                m, false
            else
                # need to truncate, so we'll have to adapt the generated code
                m - 2^W, true
            end
            return (; M, s, a)
        end
    end
    error("Can't find p, something is wrong.")
end

function emit_fast_div(n::Symbol, T::Type{<:Unsigned}, d::Integer)
    W = big(sizeof(T)*8)

    # corner cases should have been handled already
    @assert d >= 2

    # find least p and m
    M, s, a = unsigned_magic(W, d)

    quote
        # calculate the quotient based on the multiplier and shift amount
        q = mulhi(n, $(M%T))
        if $a
            t = n - q
            t >>= 1
            t = t + q
            q = t >> $(T(s)-1)
        else
            q >>= $(T(s))
        end
        q
    end
end


#
# fldmod
#

@inline @generated function fast_fldmod(n::T, ::Val{d}) where {T <: Signed, d}
    # corner cases
    if d == 1
        return :(n, zero(T))
    elseif d == -1
        return :(-n, zero(T))
    elseif d == 0
        throw(DivideError())
    end

    q_ex = if d > 0
        emit_fast_div(:n, T, d)
    else
        # we handle negative divisors by negating the quotient
        :(-$(emit_fast_div(:n, T, abs(widen(d)))))
    end

    quote
        q = $q_ex

        # recover the remainder
        r = n - q*$(T(d))

        # div rounds to zero, so we need to adjust to match fld (which rounds down)
        if r != 0 && signbit(n) != signbit(d)
            q -= one(T)
            r += $(T(d))
        end

        q, r
    end
end

@generated function fast_fldmod(n::T, ::Val{d}) where {T <: Unsigned, d}
    # XXX: Base.fldmod supports Unsigned / Signed, but what does that even mean?
    @assert d >= 0

    # corner cases
    if d == 1
        return :(n, zero(T))
    elseif d == 0
        throw(DivideError())
    end

    quote
        q = $(emit_fast_div(:n, T, d))

        # recover the remainder
        r = n - q*$(T(d))

        q, r
    end
end

@inline function fast_fldmod1(n::T, d) where T
    q0, r0 = fast_fldmod(n-one(T), d)
    q0+one(T), r0+one(T)
end
