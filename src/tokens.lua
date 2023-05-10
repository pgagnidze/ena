local lpeg = require "lpeg"
local P, C = lpeg.P, lpeg.C
local l = require "literals"
local endToken = require("common").endToken

local function T(tokenize)
    return tokenize * endToken
end

local module = {op = {}, delim = {}, sep = {}, kw = {}}

function module.KW(keyword)
    if not module.kw[keyword] then
        module.kw[keyword] = keyword * -lpeg.locale().alnum * endToken
    end

    return module.kw[keyword]
end

-- Delimiters
module.delim.openArray = T(l.delim.openArray)
module.delim.closeArray = T(l.delim.closeArray)
module.delim.openFactor = T(l.delim.openFactor)
module.delim.closeFactor = T(l.delim.closeFactor)
module.delim.openBlock = T(l.delim.openBlock)
module.delim.closeBlock = T(l.delim.closeBlock)
module.delim.openFunctionParameterList = T(l.delim.openFunctionParameterList)
module.delim.closeFunctionParameterList = T(l.delim.closeFunctionParameterList)

-- Separators
module.sep.statement = T(l.sep.statement)

module.op.assign = T(l.op.assign)
module.op.sum = T(C(P(l.op.add) + l.op.subtract))
module.op.term = T(C(P(l.op.multiply) + l.op.divide + l.op.modulus))
module.op.exponent = T(C(l.op.exponent))
module.op.comparison =
    T(
    (C(l.op.greaterOrEqual) + C(l.op.greater) + C(l.op.lessOrEqual) + C(l.op.less) + C(l.op.equal) + C(l.op.notEqual))
)
module.op.unarySign = T(C(P(l.op.positive) + l.op.negate))
module.op.not_ = T(C(l.op.not_))
module.op.print = T(l.op.print)
module.op.logical = T(C(l.op.and_) + C(l.op.or_))

return module
