local module = {}
local Transpiler = {}

function Transpiler:new(o)
    o = o or {}
    self.__index = self
    setmetatable(o, self)
    return o
end

function Transpiler:transpile(node, indentLevel)
    indentLevel = indentLevel or 0

    local indent = string.rep(" ", indentLevel * 4)
    local result = ""

    if node == nil then
        error("Attempted to transpile nil node.")
    end

    if node.tag == "function" then
        local params = {}
        for _, param in pairs(node.params) do
            table.insert(params, param)
        end
        local defaultArgs = ""
        if node.defaultArgument and node.defaultArgument.value then
            defaultArgs = params[1] .. " = " .. params[1] .. " or " .. node.defaultArgument.value .. "\n" .. indent
        end
        result =
            "function " ..
            node.name ..
                "(" ..
                    table.concat(params, ", ") ..
                        ")\n" .. defaultArgs .. self:transpile(node.block, indentLevel + 1) .. indent .. "end\n"
    elseif node.tag == "block" then
        local body = ""
        if node.body.tag == "if" then
            body =
                body ..
                indent ..
                    "if " ..
                    self:transpile(node.body.expression, indentLevel) ..
                            " then\n" .. self:transpile(node.body.block, indentLevel + 1)
            if node.body.elseBlock then
                body =
                    body ..
                    indent .. "else\n" .. self:transpile(node.body.elseBlock, indentLevel + 1) .. indent .. "end\n"
            else
                body = body .. "\n"
            end
        elseif node.body.tag == "return" then
            body = body .. indent .. "return " .. self:transpile(node.body.sentence, indentLevel) .. "\n"
        elseif node.body.tag == "statementSequence" then
            self:transpile(node.body.firstChild, indentLevel)
            self:transpile(node.body.secondChild, indentLevel)
        else
            error("Unknown block node tag: " .. node.body.tag)
        end
        result = body
    elseif node.tag == "binaryOp" then
        local op = node.op
        if op == "!=" then
            op = "~="
        end
        result =
        self:transpile(node.firstChild, indentLevel) ..
            " " .. op .. " " .. self:transpile(node.secondChild, indentLevel)
    elseif node.tag == "return" then
        result = "return " .. self:transpile(node.sentence, indentLevel)
    elseif node.tag == "number" or node.tag == "variable" then
        result = node.value
    -- elseif node.tag == "assignment" then
    --     -- todo: handle multiple assignments
    -- elseif node.tag == "statementSequence" then
    --     self:transpile(node.firstChild, indentLevel)
    --     self:transpile(node.secondChild, indentLevel)
    elseif node.tag == "functionCall" then
        local args = {}
        if node.args then
            for _, arg in pairs(node.args) do
                table.insert(args, self:transpile(arg, indentLevel))
            end
        end
        result = node.name .. "(" .. table.concat(args, ", ") .. ")"
    else
        error("Unknown node tag: " .. node.tag)
    end
    return result
end

function module.transpile(ast)
    local transpiler = Transpiler:new()
    local luaCode = ""
    for i, node in ipairs(ast) do
        luaCode = luaCode .. transpiler:transpile(node)
    end
    luaCode = luaCode .. "\nmain()"
    return luaCode
end

return module
