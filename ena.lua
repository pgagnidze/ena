#!/usr/bin/env lua

package.path = package.path .. ";ena/?.lua"

local common = require "ena.helper.common"
local parser = require "ena.parser"
local interpreter = require "ena.interpreter"
local translator = require "ena.lang.translator"
local compiler = require "ena.compiler"
local transpiler = require "ena.transpiler"
local pt = require "ena.helper.pt"

-- help --
if arg[1] == "--help" or arg[1] == "-h" then
    local options = {
        {"--help", "-h", "Show this help message."},
        {"--input", "-i", "Specify the input file."},
        {"--ast", "-a", "Show abstract syntax tree."},
        {"--code", "-c", "Show generated code."},
        {"--trace", "-t", "Trace the program."},
        {"--result", "-r", "Show the result."},
        {"--pegdebug", "-p", "Run the PEG debugger."},
        {"--transpile", "-tp", "Transpile to Lua. (experimental)"},
        {"--translate", "-tr", "Translate messages to Georgian."}
    }

    io.stdout:write(string.format("Usage: %s -i [filename] [options]\n\n", arg[0]))
    io.stdout:write("ენა - Ena, the first Georgian programming language.\n\n")
    io.stdout:write("Options:\n")

    for _, option in ipairs(options) do
        io.stdout:write(string.format("\t%-15s%-10s%s\n", option[1], option[2], option[3]))
    end

    os.exit(0)
end

-- tests --
if arg[1] ~= nil and (string.lower(arg[1]) == "--tests") then
    arg[1] = nil
    _G.lu = require "luaunit"
    _G.testEna = require("ena.spec.e2e"):init(parser.parse, compiler, interpreter)
    _G.grammar = grammar
    os.exit(_G.lu.LuaUnit.run())
end

-- arguments --
local show = {}
local awaiting_filename = false
for index, argument in ipairs(arg) do
    local lower_arg = argument:lower()
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
    elseif lower_arg == "--input" or lower_arg == "-i" then
        awaiting_filename = true
    elseif lower_arg == "--ast" or lower_arg == "-a" then
        show.AST = true
    elseif lower_arg == "--code" or lower_arg == "-c" then
        show.code = true
    elseif lower_arg == "--trace" or lower_arg == "-t" then
        show.trace = true
    elseif lower_arg == "--result" or lower_arg == "-r" then
        show.result = true
    elseif lower_arg == "--pegdebug" or lower_arg == "-p" then
        show.pegdebug = true
    elseif lower_arg == "--translate" or lower_arg == "-tr" then
        show.translate = true
    elseif lower_arg == "--transpile" or lower_arg == "-tp" then
        show.transpile = true
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

-- motd --
if arg[1] == nil then
    io.stdout:write(
        [[
ენა - Ena

პირველი ქართული პროგრამული ენა.
შეიყვანე კოდი ქვემოთ და დააჭირე Ctrl+D რომ გაეშვას.

the first Georgian programming language.
Enter the code here and press Ctrl+D to run it.

    ]] ..
            "\n"
    )
end

-- parse --
local input = io.read "a"
local ast = parser.parse(input, show.pegdebug)
if not ast then
    local furthestMatch = common.getFurthestMatch()
    local newlineCount = common.count("\n", input:sub(1, furthestMatch))
    local errorLine = newlineCount + 1
    io.stderr:write(
        (show.translate and translator.err.syntaxErrAtLine or "syntax error near line") .. " " .. errorLine .. "\n"
    )
    io.stderr:write(
        string.sub(input, furthestMatch - 20, furthestMatch - 1) ..
            "|" .. string.sub(input, furthestMatch, furthestMatch + 21) .. "\n"
    )
    os.exit(1)
end
if show.AST then
    io.stdout:write((show.translate and translator.success.showAST or "AST") .. ":\n" .. pt.pt(ast) .. "\n\n")
end

-- compile --
local code = compiler.compile(ast, show.translate)
if code == nil then
    io.stderr:write(
        (show.translate and translator.err.codeError or "Failed to generate code from input") ..
            ":\n" .. input .. "\nAST:\n" .. pt.pt(ast) .. "\n"
    )
    os.exit(1)
end
if show.code then
    io.stdout:write(
        (show.translate and translator.success.showCode or "Generated code") .. ":\n" .. pt.pt(code) .. "\n\n"
    )
end

-- execute --
local trace = {}
local result = interpreter.execute(code, trace, show.translate)
if show.trace then
    io.stdout:write((show.translate and translator.success.showTrace or "Execution trace") .. ":\n")
    for k, v in ipairs(trace) do
        io.stdout:write(k, " ", v, "\n")
        if trace.stack[k] then
            for i = #trace.stack[k], 1, -1 do
                io.stdout:write("\t\t\t", tostring(trace.stack[k][i]), "\n")
            end
            if #trace.stack[k] == 0 then
                io.stdout:write("\t\t\t(empty)\n")
            end
        end
    end
    io.stdout:write("\n")
end
if show.result then
    io.stdout:write((show.translate and translator.success.showResult or "Result") .. ":\n", tostring(result), "\n\n")
end

-- transpile: experimental --
if show.transpile then
    local transpiledCode = transpiler.transpile(ast)
    io.stdout:write(
        (show.translate and translator.success.showTranspile or "Transpiled") .. ":\n",
        tostring(transpiledCode),
        "\n"
    )
end
