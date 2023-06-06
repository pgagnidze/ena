local module = {kw = {}}
local literals = require "ena.lang.literals"
local translator = require "ena.lang.translator"
local lpeg = require "lpeg"
local common = require "ena.helper.common"
local endToken = common.endToken
local l = literals

-- patterns --
local P, R, S = lpeg.P, lpeg.R, lpeg.S
local Cmt = lpeg.Cmt

-- captures --
local C, Cc = lpeg.C, lpeg.Cc

-- helper --
-- numeral
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

-- identifier
local function getIdentifier(subject, position, match)
    if module.kw[match] then
        return false
    else
        return true, match
    end
end

-- token
local function T(tokenize)
    return tokenize * endToken
end

function module.KW(keyword)
    if not module.kw[keyword] then
        module.kw[keyword] = keyword * -lpeg.locale().alnum * endToken
    end

    return module.kw[keyword]
end
local KW = module.KW

-- string literal
local function escapeSequence(s)
    return s:gsub(
        "\\.",
        {
            ["\\"] = "\\",
            ["'"] = "'",
            ['"'] = '"',
            ["n"] = "\n",
            ["r"] = "\r",
            ["t"] = "\t"
        }
    )
end

-- identifier --
local geoalpha = S(translator.alphabet)
local alpha = R("AZ", "az") + geoalpha
local identifierStartCharacters = (alpha + "_")
local digit = R "09"
local identifierTailCharacters = (alpha + digit + "_")
local identifierPattern = Cmt(identifierStartCharacters * identifierTailCharacters ^ 0, getIdentifier) * endToken

-- numeral --
local sign = S("+-") * endToken
local decimalStart = R "19"
local decimalDigit = R "09"
local numeralExponent = S "eE" * sign ^ -1 * (P " " ^ -1 * decimalDigit) ^ 0
local fractionOptional = ("." * (P " " ^ -1 * decimalDigit) ^ 0) ^ -1
local fraction = ("." * (P " " ^ -1 * decimalDigit) ^ 1)
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
local baseStart = "0" * (baseStartDigit / digitToBase) * P " " ^ -1
local baseNumeral = (baseStart * C(baseDigit ^ 1))
local numeral = (baseNumeral + decimalNumeral) / toNumberWithUnary * endToken

-- tokens --
local tokens = {op = {}, delim = {}, sep = {}, kw = {}}

-- delimiters
tokens.delim.openArray = T(l.delim.openArray)
tokens.delim.closeArray = T(l.delim.closeArray)
tokens.delim.openFactor = T(l.delim.openFactor)
tokens.delim.closeFactor = T(l.delim.closeFactor)
tokens.delim.openBlock = T(l.delim.openBlock)
tokens.delim.closeBlock = T(l.delim.closeBlock)
tokens.delim.openFunctionParameterList = T(l.delim.openFunctionParameterList)
tokens.delim.closeFunctionParameterList = T(l.delim.closeFunctionParameterList)

-- separators
tokens.delim.functionParameterSeparator = T(l.delim.functionParameterSeparator)
tokens.sep.statement = T(l.sep.statement)
tokens.op.assign = T(l.op.assign)
tokens.op.sum = T(C(P(l.op.add) + l.op.subtract))
tokens.op.term = T(C(P(l.op.multiply) + l.op.divide + l.op.modulus))
tokens.op.exponent = T(C(l.op.exponent))
tokens.op.comparison =
    T(
    (C(l.op.greaterOrEqual) + C(l.op.greater) + C(l.op.lessOrEqual) + C(l.op.less) + C(l.op.equal) + C(l.op.notEqual))
)
tokens.op.unarySign = T(C(P(l.op.positive) + l.op.negate))
tokens.op.not_ = T(C(l.op.not_))
tokens.op.print = T(l.op.print)
tokens.op.exec = T(l.op.exec)
tokens.op.logical = T(C(l.op.and_) + C(l.op.or_))

local op = tokens.op
local sep = tokens.sep
local delim = tokens.delim

-- string literal --
local doubleQuoteString = P('"') * C((P('\\"') + P("\\\\") + P(1) - P('"')) ^ 0) / escapeSequence * P('"') * endToken
local singleQuoteString = P("'") * C((P("\\'") + P("\\\\") + P(1) - P("'")) ^ 0) / escapeSequence * P("'") * endToken
local stringLiteral = doubleQuoteString + singleQuoteString

-- abstract syntax tree --
local function node(tag, ...)
    local labels = table.pack(...)
    local params = table.concat(labels, ", ")
    local fields = string.gsub(params, "(%w+)", "%1 = %1")
    local code = string.format("return function (%s) return {tag = '%s', %s} end", params, tag, fields)
    return assert(load(code))()
end

local nodeVariable = node("variable", "value")
local nodeAssignment = node("assignment", "writeTarget", "assignment")
local nodePrint = node("print", "toPrint")
local nodeExec = node("exec", "command")
local nodeReturn = node("return", "sentence")
local nodeNumeral = node("number", "value")
local nodeIf = node("if", "expression", "block", "elseBlock")
local nodeBoolean = node("boolean", "value")
local nodeNil = node("nil")
local nodeWhile = node("while", "expression", "block")
local nodeFunction = node("function", "name", "params", "defaultArgument", "block")
local nodeFunctionCall = node("functionCall", "name", "args")
local nodeLocalVariable = node("local", "name", "init")
local nodeString = node("string", "value")

local function nodeStatementSequence(first, rest)
    -- When first is empty, rest is nil, so we return an empty statement.
    -- This can happen if there is a sequence of statement separators at the end, e.g. "1;2;;",
    -- if there are no statements at all, e.g. "", or if there are ONLY statement separators, e.g. ";;".
    if first == "" then
        -- If first is NOT empty, but rest is nil or empty, we can prune rest and just return first.
        return {tag = "emptyStatement"}
    elseif rest == nil or rest.tag == "emptyStatement" then
        -- If first is an empty statement, but rest isn't, we can prune the empty statement and return rest.
        return first
    elseif first.tag == "emptyStatement" then
        -- Otherwise, both first and rest are non-empty statements, so we need to return a statement sequence.
        return rest
    else
        return {tag = "statementSequence", firstChild = first, secondChild = rest}
    end
end

local function nodeBlock(body)
    if body == "" then
        return {tag = "emptyBlock"}
    else
        return {tag = "block", body = body}
    end
end

local function addUnaryOp(operator, expression)
    return {tag = "unaryOp", op = operator, child = expression}
end

local function addExponentOp(expression1, op, expression2)
    if op then
        return {tag = "binaryOp", firstChild = expression1, op = op, secondChild = expression2}
    else
        return expression1
    end
end

local function foldBinaryOps(list)
    local tree = list[1]
    for i = 2, #list, 2 do
        tree = {tag = "binaryOp", firstChild = tree, op = list[i], secondChild = list[i + 1]}
    end
    return tree
end

local function foldArrayElement(list)
    local tree = list[1]
    for i = 2, #list do
        tree = {tag = "arrayElement", array = tree, index = list[i]}
    end
    return tree
end

local function foldNewArray(list, initialValue)
    local tree = initialValue
    for i = #list, 1, -1 do
        tree = {tag = "newArray", initialValue = tree, size = list[i]}
    end
    return tree
end

-- grammar --
local V = lpeg.V
local primary, exponentExpr, termExpr = V "primary", V "exponentExpr", V "termExpr"
local sumExpr, comparisonExpr, unaryExpr, logicExpr = V "sumExpr", V "comparisonExpr", V "unaryExpr", V "logicExpr"
local notExpr = V "notExpr"
local statement, statementList = V "statement", V "statementList"
local elses = V "elses"
local blockStatement = V "blockStatement"
local expression = V "expression"
local boolean = V "boolean"
local variable = V "variable"
local identifier = V "identifier"
local writeTarget = V "writeTarget"
local funcDec = lpeg.V "funcDec"
local functionCall = lpeg.V "functionCall"
local funcParams = lpeg.V "funcParams"
local funcArgs = lpeg.V "funcArgs"

local KW_function =
    (KW "function" + KW(translator.kwords.longForm.keyFunction) + KW(translator.kwords.shortForm.keyFunction))
local KW_elseif = (KW "elseif" + KW(translator.kwords.longForm.keyElseIf) + KW(translator.kwords.shortForm.keyElseIf))
local KW_else = (KW "else" + KW(translator.kwords.longForm.keyElse) + KW(translator.kwords.shortForm.keyElse))
local KW_local = (KW "local" + KW(translator.kwords.longForm.keyLocal) + KW(translator.kwords.shortForm.keyLocal))
local KW_if = (KW "if" + KW(translator.kwords.longForm.keyIf) + KW(translator.kwords.shortForm.keyIf))
local KW_return = (KW "return" + KW(translator.kwords.longForm.keyReturn) + KW(translator.kwords.shortForm.keyReturn))
local KW_while = (KW "while" + KW(translator.kwords.longForm.keyWhile) + KW(translator.kwords.shortForm.keyWhile))
local kW_print = (op.print + KW(translator.kwords.longForm.keyPrint) + KW(translator.kwords.shortForm.keyPrint))
local KW_exec = (op.exec + KW(translator.kwords.longForm.keyExec) + KW(translator.kwords.shortForm.keyExec))
local KW_true = (KW "true" + KW(translator.values.longForm.valTrue) + KW(translator.values.shortForm.valTrue))
local KW_false = (KW "false" + KW(translator.values.longForm.valFalse) + KW(translator.values.shortForm.valFalse))
local KW_new = (KW "new" + KW(translator.kwords.longForm.keyNew) + KW(translator.kwords.shortForm.keyNew))
local KW_nil = (KW "nil" + KW(translator.values.longForm.valNil) + KW(translator.values.shortForm.valNil))

local Ct = lpeg.Ct
local grammar = {
    "program",
    program = endToken * Ct(funcDec ^ 1) * -1,
    funcDec = KW_function * identifier * delim.openFunctionParameterList * funcParams *
        ((op.assign * expression) + Cc({})) *
        delim.closeFunctionParameterList *
        blockStatement /
        nodeFunction,
    funcParams = Ct((identifier * (delim.functionParameterSeparator * identifier) ^ 0) ^ -1),
    statementList = statement * (sep.statement ^ -1 * statementList) ^ -1 / nodeStatementSequence,
    blockStatement = delim.openBlock * (statementList ^ -1 / nodeBlock) * sep.statement ^ -1 * delim.closeBlock,
    elses = (KW_elseif * expression * blockStatement) * elses / nodeIf + (KW_else * blockStatement) ^ -1,
    variable = identifier / nodeVariable,
    functionCall = identifier * delim.openFunctionParameterList * funcArgs * delim.closeFunctionParameterList /
        nodeFunctionCall,
    funcArgs = Ct((expression * (delim.functionParameterSeparator * expression) ^ 0) ^ -1),
    writeTarget = Ct(variable * (delim.openArray * expression * delim.closeArray) ^ 0) / foldArrayElement,
    statement = blockStatement + functionCall +
        writeTarget * (op.assign * expression) ^ -1 * -delim.openBlock / nodeAssignment +
        KW_local * identifier * (op.assign * expression) ^ -1 / nodeLocalVariable +
        KW_if * expression * blockStatement * elses / nodeIf +
        KW_return * expression / nodeReturn +
        KW_while * expression * blockStatement / nodeWhile +
        kW_print * expression / nodePrint +
        KW_exec * expression / nodeExec,
    boolean = (KW_true * Cc(true) + KW_false * Cc(false)) / nodeBoolean,
    primary = Ct(KW_new * (delim.openArray * expression * delim.closeArray) ^ 1) * primary / foldNewArray + functionCall +
        writeTarget +
        stringLiteral / nodeString +
        numeral / nodeNumeral +
        boolean +
        KW_exec * expression / nodeExec +
        KW_nil / nodeNil +
        delim.openFactor * expression * delim.closeFactor,
    exponentExpr = primary * (op.exponent * exponentExpr) ^ -1 / addExponentOp,
    unaryExpr = op.unarySign * unaryExpr / addUnaryOp + exponentExpr,
    termExpr = Ct(unaryExpr * (op.term * unaryExpr) ^ 0) / foldBinaryOps,
    sumExpr = Ct(termExpr * (op.sum * termExpr) ^ 0) / foldBinaryOps,
    notExpr = op.not_ * notExpr / addUnaryOp + sumExpr,
    comparisonExpr = Ct(notExpr * (op.comparison * notExpr) ^ 0) / foldBinaryOps,
    logicExpr = Ct(comparisonExpr * (op.logical * comparisonExpr) ^ 0) / foldBinaryOps,
    expression = logicExpr,
    endToken = common.endTokenPattern,
    identifier = identifierPattern
}

function module.parse(input, pegdebug)
    if pegdebug then
        grammar = require("ena.helper.pegdebug").trace(grammar)
    end
    grammar = lpeg.P(grammar)
    common.clearFurthestMatch()
    return grammar:match(input)
end

return module
