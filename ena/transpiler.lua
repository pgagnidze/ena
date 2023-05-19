local module = {}
local Transpiler = {}
local translator = require "ena.lang.translator"

function Transpiler:new()
    return setmetatable({}, {__index = self})
end

local handlers = {
    ["function"] = function(transpiler, node, indentLevel, indent)
        local params = {}
        for _, param in pairs(node.params) do
            if param then
                table.insert(params, param)
            end
        end
        local defaultArgs = ""
        if node.defaultArgument and node.defaultArgument.value then
            defaultArgs =
                string.rep("    ", indentLevel + 1) ..
                params[1] .. " = " .. params[1] .. " or " .. node.defaultArgument.value .. "\n" .. indent
        end
        return "function " ..
            node.name ..
                "(" ..
                    table.concat(params, ", ") ..
                        ")\n" .. defaultArgs .. transpiler:transpile(node.block, indentLevel + 1) .. indent .. "end\n"
    end,
    ["functionCall"] = function(transpiler, node, indentLevel, indent)
        local args = {}
        if node.args then
            for _, arg in pairs(node.args) do
                if arg then
                    table.insert(args, transpiler:transpile(arg, indentLevel))
                end
            end
        end
        return node.name .. "(" .. table.concat(args, ", ") .. ")"
    end,
    ["block"] = function(transpiler, node, indentLevel, indent)
        return transpiler:transpile(node.body, indentLevel)
    end,
    ["if"] = function(transpiler, node, indentLevel, indent)
        local elseBlock = ""
        local elseIfBlocks = ""
        local condition = transpiler:transpile(node.expression, indentLevel)
        local body = transpiler:transpile(node.block, indentLevel + 1)
        local nextBlock = node.elseBlock
        while nextBlock do
            if nextBlock.tag == "if" then
                elseIfBlocks =
                    elseIfBlocks ..
                    indent ..
                        "elseif " ..
                            transpiler:transpile(nextBlock.expression) ..
                                " then\n" .. transpiler:transpile(nextBlock.block, indentLevel + 1)
                nextBlock = nextBlock.elseBlock
            else
                elseBlock = indent .. "else\n" .. transpiler:transpile(nextBlock, indentLevel + 1)
                break
            end
        end
        return indent ..
            "if " ..
                condition ..
                    " then\n" ..
                        body ..
                            (elseIfBlocks ~= "" and elseIfBlocks or "") ..
                                (elseBlock ~= "" and elseBlock or "") .. indent .. "end\n"
    end,
    ["while"] = function(transpiler, node, indentLevel, indent)
        local condition = transpiler:transpile(node.expression, indentLevel)
        local body = transpiler:transpile(node.block.body, indentLevel + 1)
        return indent .. "while " .. condition .. " do\n" .. body .. "\n" .. indent .. "end"
    end,
    ["arrayElement"] = function(transpiler, node, indentLevel, indent)
        local array = transpiler:transpile(node.array, indentLevel)
        local index = transpiler:transpile(node.index, indentLevel)
        return array .. "[" .. index .. "]"
    end,
    ["newArray"] = function(transpiler, node, indentLevel, indent)
        local size = transpiler:transpile(node.size, indentLevel)
        local initialValue = transpiler:transpile(node.initialValue, indentLevel)
        local arrayElements = {}
        for _ = 1, size do
            table.insert(arrayElements, initialValue)
        end
        return "{" .. table.concat(arrayElements, ", ") .. "}"
    end,
    ["statementSequence"] = function(transpiler, node, indentLevel, indent)
        local firstChild = (node.firstChild and transpiler:transpile(node.firstChild, indentLevel)) or ""
        local secondChild = (node.secondChild and transpiler:transpile(node.secondChild, indentLevel)) or ""
        return (firstChild ~= "" and firstChild .. "\n" or "") .. secondChild
    end,
    ["assignment"] = function(transpiler, node, indentLevel, indent)
        local target = transpiler:transpile(node.writeTarget, indentLevel)
        local value = transpiler:transpile(node.assignment, indentLevel)
        return indent .. target .. " = " .. value
    end,
    ["local"] = function(transpiler, node, indentLevel, indent)
        local init = transpiler:transpile(node.init, indentLevel)
        return indent .. "local " .. node.name .. " = " .. init
    end,
    ["boolean"] = function(transpiler, node, indentLevel, indent)
        return tostring(node.value)
    end,
    ["number"] = function(transpiler, node, indentLevel, indent)
        return node.value
    end,
    ["string"] = function(transpiler, node, indentLevel, indent)
        return '"' .. node.value .. '"'
    end,
    ["nil"] = function(transpiler, node, indentLevel, indent)
        return "nil"
    end,
    ["print"] = function(transpiler, node, indentLevel, indent)
        return indent .. "print(" .. transpiler:transpile(node.toPrint, indentLevel) .. ")"
    end,
    ["variable"] = function(transpiler, node, indentLevel, indent)
        return node.value
    end,
    ["emptyStatement"] = function(transpiler, node, indentLevel, indent)
        return indent
    end,
    ["binaryOp"] = function(transpiler, node, indentLevel, indent)
        local op = node.op
        if op == "&" then
            op = "and"
        elseif op == "|" then
            op = "or"
        elseif op == "!=" then
            op = "~="
        end
        return transpiler:transpile(node.firstChild, indentLevel) ..
            " " .. op .. " " .. transpiler:transpile(node.secondChild, indentLevel)
    end,
    ["unaryOp"] = function(transpiler, node, indentLevel, indent)
        local op = node.op
        if op == "!" then
            op = "not"
        end
        return op .. " " .. transpiler:transpile(node.child, indentLevel)
    end,
    ["return"] = function(transpiler, node, indentLevel, indent)
        return indent .. "return " .. transpiler:transpile(node.sentence, indentLevel) .. "\n"
    end
}

local function replaceGeorgianCharacters(luaCode)
    for georgian, english in pairs(translator.toeng) do
        luaCode = luaCode:gsub(georgian, english)
    end
    return luaCode
end

function Transpiler:transpile(node, indentLevel)
    indentLevel = indentLevel or 0
    local indent = string.rep(" ", indentLevel * 4)
    if node == nil then
        return "nil"
    end
    local handler = handlers[node.tag]
    if handler then
        return handler(self, node, indentLevel, indent)
    else
        error("Unknown node tag: " .. node.tag)
    end
end

function module.transpile(ast)
    local transpiler = Transpiler:new()
    local luaCodeParts = {}
    for _, node in ipairs(ast) do
        table.insert(luaCodeParts, transpiler:transpile(node))
    end
    table.insert(luaCodeParts, "\nmain()")
    local luaCode = table.concat(luaCodeParts, "")
    return replaceGeorgianCharacters(luaCode)
end

return module
