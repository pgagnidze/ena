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
local nodeAssignment = node("assignment", "writeTarget", "assignment")
local nodePrint = node("print", "toPrint")
local nodeReturn = node("return", "sentence")
local nodeNumeral = node("number", "value")
local nodeIf = node("if", "expression", "block", "elseBlock")
local nodeWhile = node("while", "expression", "block")
local nodeNewArray = node("newArray", "sizes", "initialValueExpression")

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

local function foldArrayElement(list)
    local tree = list[1]
    for i = 2, #list do
        tree = {tag = "arrayElement", array = tree, index = list[i]}
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
local variable = V "variable"
local writeTarget = V "writeTarget" -- left-hand side

local Ct = lpeg.Ct
local grammar = {
    "program",
    program = endToken * statementList * -1,
    statementList = statement ^ -1 * (sep.statement * statementList) ^ -1 / nodeStatementSequence,
    blockStatement = delim.openBlock * statementList * sep.statement ^ -1 * delim.closeBlock,
    elses = ((KW "elseif" + KW(translator.kwords.longForm.keyElseIf) + KW(translator.kwords.shortForm.keyElseIf)) *
        expression *
        blockStatement) *
        elses /
        nodeIf +
        ((KW "else" + KW(translator.kwords.longForm.keyElse) + KW(translator.kwords.shortForm.keyElse)) * blockStatement) ^
            -1,
    variable = identifier / nodeVariable,
    writeTarget = Ct(variable * (delim.openArray * expression * delim.closeArray) ^ 0) / foldArrayElement,
    statement = blockStatement + -- Assignment - must be first to allow variables that contain keywords as prefixes.
        writeTarget * op.assign * expression * -delim.openBlock / nodeAssignment + -- If
        (KW "if" + KW(translator.kwords.longForm.keyIf) + KW(translator.kwords.shortForm.keyIf)) * expression *
            blockStatement *
            elses /
            nodeIf + -- Return
        (KW "return" + KW(translator.kwords.longForm.keyReturn) + KW(translator.kwords.shortForm.keyReturn)) *
            expression /
            nodeReturn + -- While
        (KW "while" + KW(translator.kwords.longForm.keyWhile) + KW(translator.kwords.shortForm.keyWhile)) * expression *
            blockStatement /
            nodeWhile + -- Print
        (op.print + KW(translator.kwords.longForm.keyPrint) + KW(translator.kwords.shortForm.keyPrint)) * expression /
            nodePrint,
    -- Identifiers and numbers
    primary = Ct(
        (KW "new" + KW(translator.kwords.longForm.keyNew) + KW(translator.kwords.shortForm.keyNew)) *
            (delim.openArray * expression * delim.closeArray) ^ 1
    ) *
        primary /
        nodeNewArray +
        writeTarget +
        numeral / nodeNumeral +
        -- Sentences in the language enclosed in parentheses
        delim.openFactor * expression * delim.closeFactor,
    -- From highest to lowest precedence
    exponentExpr = primary * (op.exponent * exponentExpr) ^ -1 / addExponentOp,
    unaryExpr = op.unarySign * unaryExpr / addUnaryOp + exponentExpr,
    termExpr = Ct(unaryExpr * (op.term * unaryExpr) ^ 0) / foldBinaryOps,
    sumExpr = Ct(termExpr * (op.sum * termExpr) ^ 0) / foldBinaryOps,
    notExpr = op.not_ * notExpr / addUnaryOp + sumExpr,
    comparisonExpr = Ct(notExpr * (op.comparison * notExpr) ^ 0) / foldBinaryOps,
    logicExpr = Ct(comparisonExpr * (op.logical * comparisonExpr) ^ 0) / foldBinaryOps,
    expression = logicExpr,
    endToken = common.endTokenPattern
}

local function parse(input)
    common.clearFurthestMatch()
    return grammar:match(input)
end

if arg[1] ~= nil and (string.lower(arg[1]) == "--help" or string.lower(arg[1]) == "-h") then
    -- If the first argument is nil, then the user has not provided a filename.
    -- So provide all the options and usage information.
    io.stdout:write("Usage: " .. arg[0] .. " -i [filename] [options]\n\n")
    io.stdout:write("ენა - Ena, the first Georgian programming language.\n\n")
    io.stdout:write("Options:\n")
    io.stdout:write("\t--help\t\t-h\t\tShow this help message.\n")
    io.stdout:write("\t--tests\t\t-ts\t\tRun the test suite.\n")
    io.stdout:write("\t--input\t\t-i\t\tSpecify the input file.\n")
    io.stdout:write("\t--ast\t\t-a\t\tShow abstract syntax tree.\n")
    io.stdout:write("\t--code\t\t-c\t\tShow generated code.\n")
    io.stdout:write("\t--trace\t\t-t\t\tTrace the program.\n")
    io.stdout:write("\t--result\t-r\t\tShow the result.\n")
    io.stdout:write("\t--pegdebug\t-p\t\tRun the PEG debugger.\n")
    io.stdout:write("\t--translate\t-tr\t\tTranslate messages to Georgian.\n")
    os.exit(0)
end

if arg[1] ~= nil and (string.lower(arg[1]) == "--tests" or string.lower(arg[1]) == "-ts") then
    arg[1] = nil
    _G.lu = require "luaunit"
    _G.testEna = require("spec.ena"):init(parse, compiler, interpreter)
    _G.testNumerals = require("spec.numeral")
    _G.testIdentifiers = require("spec.identifier")
    _G.grammar = grammar

    grammar = lpeg.P(grammar)

    os.exit(_G.lu.LuaUnit.run())
end

local show = {}
local awaiting_filename = false
for index, argument in ipairs(arg) do
    if awaiting_filename then
        local status, err = pcall(io.input, arg[index])
        if not status then
            io.stderr:write(
                "Could not open file" ..
                    " | " .. translator.err.fileOpen .. ": " .. arg[index] .. '"\n\tError: ' .. err .. "\n"
            )
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
    io.stderr:write(
        show.translate and translator.err.noInputFile .. "\n" or "Specified -i, but no input file found." .. "\n"
    )
    os.exit(1)
end

print([[
ენა - Ena, the first Georgian programming language.
Enter the code here and press Ctrl+D to run it.
]])

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
    io.stdout:write((show.translate and translator.success.showAST or "AST") .. ":\n" .. pt.pt(ast), "\n\n")
end

-- compile --
local code = compiler.compile(ast, show.translate)
if code == nil then
    io.stderr:write(
        (show.translate and translator.err.codeError or "Failed generate code from input"),
        ":\n",
        input,
        "\nAST:",
        "\n",
        pt.pt(ast),
        "\n"
    )
    return 1
end

if show.code then
    io.stdout:write(
        (show.translate and translator.success.showCode or "Generated code") .. ":\n" .. pt.pt(code),
        "\n\n"
    )
end

-- execute --
local trace = {}
local result = interpreter.run(code, trace, show.translate)
if show.trace then
    io.stdout:write((show.translate and translator.success.showTrace or "Execution trace") .. ":\n")
    for k, v in ipairs(trace) do
        print(k, v)
    end
    io.stdout:write("\n")
end
if show.result then
    io.stdout:write((show.translate and translator.success.showResult or "Result") .. ":\n", result, "\n\n")
end
