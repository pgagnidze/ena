local lpeg = require "lpeg"

-- Patterns
local P, R, S = lpeg.P, lpeg.R, lpeg.S
-- Captures
local C, Cc = lpeg.C, lpeg.Cc

local endToken = require("common").endToken

local sign = S("+-") * endToken
-- Digits may be separated by single spaces for digit grouping purposes, so allow optional spaces.
local decimalStart = R "19"
local decimalDigit = R "09"
local numeralExponent = S "eE" * sign ^ -1 * (P " " ^ -1 * decimalDigit) ^ 0

-- An optional (decimal point followed by zero or more decimal digits).
local fractionOptional = ("." * (P " " ^ -1 * decimalDigit) ^ 0) ^ -1
-- A required decimal point followed by at least one decimal digit.
local fraction = ("." * (P " " ^ -1 * decimalDigit) ^ 1)

-- Matches a positive nonzero numeral.
local naturalNumber = decimalStart * (P " " ^ -1 * decimalDigit) ^ 0

-- A decimal number is a natural number followed by an optional fractional part, followed by an optional exponent, OR
local decimalNumeral =
    Cc(nil) *
    C(
        (naturalNumber * fractionOptional * numeralExponent ^ -1) +
            -- A zero followed by an optional fractional part, followed by an optional exponent, OR
            (P "0" * fractionOptional * numeralExponent ^ -1) +
            -- A fractional part followed by an optional exponent.
            fraction * numeralExponent ^ -1
    )

local baseStartDigit = R("09", "az", "AZ")
local baseDigit = R("09", "az", "AZ") * P " " ^ -1
local function digitToBase(d)
    -- Base is one more than the numeric value of the digit.

    -- tonumber doesn't work for single-digit numbers over 9
    local number = tonumber(d)
    if number then
        -- 01 is base 2, 07 is base 8, 0f is base 16: So we need to add 11.
        return number + 1
    else
        return d:lower():byte(1, 1) - ("a"):byte(1, 1) + 11
    end
end

local baseStart = "0" * (baseStartDigit / digitToBase) * P " " ^ -1
local baseNumeral = (baseStart * C(baseDigit ^ 1))

local function toNumberWithUnary(base, num)
    -- Remove optional space separators/any captured trailing spaces.
    num = num:gsub("%s+", "")

    if not base or base > 1 then
        return tonumber(num, base)
    else
        if #(num:gsub("1", "")) == 0 then
            return #num
        else
            error('invalid unary number "' .. num .. '"')
        end
    end
end

return (baseNumeral + decimalNumeral) / toNumberWithUnary * endToken
