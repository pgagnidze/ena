#!/usr/bin/env lua

local interpreter = require "interpreter"
local translator = require "translator"
local compiler = require "compiler"

local lpeg = require "lpeg"
local pt = require "external.pt"
local common = require "common"
local endToken = common.endToken
local numeral = require "numeral"
local identifier = require "identifier"

local tokens = require "tokens"
local op = tokens.op
local KW = tokens.KW
local sep = tokens.sep
local delim = tokens.delim

-- abstract syntax tree --
local function node(tag, ...)
    local labels = table.pack(...)
    local params = table.concat(labels, ", ")
    local fields = string.gsub(params, "(%w+)", "%1 = %1")
    local code = string.format("return function (%s) return {tag = '%s', %s} end", params, tag, fields)
    return assert(load(code))()
end

local nodeVariable = node("variable", "value")
local nodeAssignment = node("assignment", "identifier", "assignment")
local nodePrint = node("print", "toPrint")
local nodeReturn = node("return", "sentence")
local nodeNumeral = node("number", "value")
local nodeIf = node("if", "expression", "block", "elseBlock")
local nodeWhile = node("while", "expression", "block")

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

-- grammar --
local V = lpeg.V
local primary, exponentExpr, termExpr = V "primary", V "exponentExpr", V "termExpr"
local sumExpr, comparisonExpr, unaryExpr, logicExpr = V "sumExpr", V "comparisonExpr", V "unaryExpr", V "logicExpr"
local notExpr = V "notExpr"
local statement, statementList = V "statement", V "statementList"
local elses = V "elses"
local blockStatement = V "blockStatement"

local Ct = lpeg.Ct
local grammar = {
    "program",
    program = endToken * statementList * -1,
    statementList = statement ^ -1 * (sep.statement * statementList) ^ -1 / nodeStatementSequence,
    blockStatement = delim.openBlock * statementList * sep.statement ^ -1 * delim.closeBlock,
    elses = ((KW "elseif" + KW(translator.kwords.longForm.keyElseIf) + KW(translator.kwords.shortForm.keyElseIf)) *
        comparisonExpr *
        blockStatement) *
        elses /
        nodeIf +
        ((KW "else" + KW(translator.kwords.longForm.keyElse) + KW(translator.kwords.shortForm.keyElse)) * blockStatement) ^
            -1,
    statement = blockStatement + -- Assignment - must be first to allow variables that contain keywords as prefixes.
        identifier * op.assign * comparisonExpr / nodeAssignment + -- If
        (KW "if" + KW(translator.kwords.longForm.keyIf) + KW(translator.kwords.shortForm.keyIf)) * comparisonExpr *
            blockStatement *
            elses /
            nodeIf + -- Return
        (KW "return" + KW(translator.kwords.longForm.keyReturn) + KW(translator.kwords.shortForm.keyReturn)) *
            comparisonExpr /
            nodeReturn + -- While
        (KW "while" + KW(translator.kwords.longForm.keyWhile) + KW(translator.kwords.shortForm.keyWhile)) *
            comparisonExpr *
            blockStatement /
            nodeWhile + -- Print
        (op.print + KW(translator.kwords.longForm.keyPrint) + KW(translator.kwords.shortForm.keyPrint)) * comparisonExpr /
            nodePrint,
    -- Identifiers and numbers
    primary = numeral / nodeNumeral + identifier / nodeVariable + -- Sentences in the language enclosed in parentheses
        delim.openFactor * comparisonExpr * delim.closeFactor,
    -- From highest to lowest precedence
    exponentExpr = primary * (op.exponent * exponentExpr) ^ -1 / addExponentOp,
    unaryExpr = op.unarySign * unaryExpr / addUnaryOp + exponentExpr,
    termExpr = Ct(unaryExpr * (op.term * unaryExpr) ^ 0) / foldBinaryOps,
    sumExpr = Ct(termExpr * (op.sum * termExpr) ^ 0) / foldBinaryOps,
    notExpr = op.unaryNot * notExpr / addUnaryOp + sumExpr,
    logicExpr = Ct(notExpr * (op.logical * notExpr) ^ 0) / foldBinaryOps,
    comparisonExpr = Ct(logicExpr * (op.comparison * logicExpr) ^ 0) / foldBinaryOps,
    endToken = common.endTokenPattern
}

local function parse(input)
    common.clearFurthestMatch()
    return grammar:match(input)
end

local show = {}
local awaiting_filename = false
for index, argument in ipairs(arg) do
    if awaiting_filename then
        local status, err = pcall(io.input, arg[index])
        if not status then
            io.stderr:write("Could not open file" .. " | " .. translator.err.fileOpen .. ": " .. arg[index] .. '"\n\tError: ' .. err .. "\n")
            os.exit(1)
        end
        awaiting_filename = false
    elseif argument:lower() == "--input" or argument:lower() == "-i" then
        awaiting_filename = true
    elseif argument:lower() == "--ast" or argument:lower() == "-a" then
        show.AST = true
    elseif argument:lower() == "--code" or argument:lower() == "-c" then
        show.code = true
    elseif argument:lower() == "--trace" or argument:lower() == "-t" then
        show.trace = true
    elseif argument:lower() == "--result" or argument:lower() == "-r" then
        show.result = true
    elseif argument:lower() == "--pegdebug" or argument:lower() == "-p" then
        show.pegdebug = true
    elseif argument:lower() == "--translate" or argument:lower() == "-tr" then
        show.translate = true
    else
        io.stderr:write("Unknown argument" .. " | " .. translator.err.unknownArg .. ": " .. argument .. "." .. "\n")
        os.exit(1)
    end
end

if awaiting_filename then
    io.stderr:write(show.translate and translator.err.noInputFile .. "\n" or "Specified -i, but no input file found." .. "\n")
    os.exit(1)
end

-- peg debug
if show.pegdebug then
    grammar = require("external.pegdebug").trace(grammar)
end
grammar = lpeg.P(grammar)

-- parse user input
local input = io.read "a"
local ast = parse(input)

-- syntax error
if not ast then
    local furthestMatch = common.getFurthestMatch()
    local newlineCount = common.count("\n", input:sub(1, furthestMatch))
    local errorLine = newlineCount + 1
    if input:sub(furthestMatch - 1, furthestMatch - 1) == "\n" then
        errorLine = errorLine - 1
        furthestMatch = furthestMatch - 1
        if input:sub(furthestMatch - 1, furthestMatch - 1) == "\r" then
            furthestMatch = furthestMatch - 1
        end
        io.stderr:write(
            show.translate and translator.err.syntaxErrAfterLine or "syntax error after line",
            " ",
            errorLine,
            "\n"
        )
    else
        io.stderr:write(
            show.translate and translator.err.syntaxErrAtLine or "syntax error at line",
            " ",
            errorLine,
            "\n"
        )
    end
    io.stderr:write(
        string.sub(input, furthestMatch - 20, furthestMatch - 1),
        "|",
        string.sub(input, furthestMatch, furthestMatch + 21),
        "\n"
    )
    return 1
end

if show.AST then
    print((show.translate and translator.success.showAST or "AST") .. ":" .. pt.pt(ast))
end

-- compile --
local code = compiler.compile(ast, show.translate)
if code == nil then
    io.stderr:write("Failed generate code from input:", "\n", input, "\nAST:", "\n", pt.pt(ast), "\n")
    return 1
end

if show.code then
    print((show.translate and translator.success.showCode or "Generated code") .. ":" ..  pt.pt(code))
end

-- execute --
local trace = {}
local result = interpreter.run(code, trace)
if show.trace then
    print((show.translate and translator.success.showTrace or "Execution trace") .. ":")
    for k, v in ipairs(trace) do
        print(k, v)
    end
end
if show.result then
    print((show.translate and translator.success.showResult or "Result") .. ":")
    print(result)
end