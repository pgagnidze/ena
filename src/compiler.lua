local module = {}
local translator = require "translator"
local lop = require("literals").op
local literals = require "literals"

local Compiler = {
    functions = {},
    variables = {},
    nvars = 0
}

local function pt(x, id, visited)
    visited = visited or {}
    id = id or ""
    if type(x) == "string" then
        return "'" .. tostring(x) .. "'"
    elseif type(x) ~= "table" then
        return tostring(x)
    elseif visited[x] then
        return "..."
    else
        visited[x] = true
        local s = id .. "{\n"
        for k, v in pairs(x) do
            s = s .. id .. tostring(k) .. " = " .. pt(v, id .. "  ", visited) .. ";\n"
        end
        s = s .. id .. "}"
        return s
    end
end

local toName = {
    [lop.add] = "add",
    [lop.subtract] = "subtract",
    [lop.multiply] = "multiply",
    [lop.divide] = "divide",
    [lop.modulus] = "modulus",
    [lop.exponent] = "exponent",
    [lop.less] = "less",
    [lop.greater] = "greater",
    [lop.lessOrEqual] = "lessOrEqual",
    [lop.greaterOrEqual] = "greaterOrEqual",
    [lop.equal] = "equal",
    [lop.notEqual] = "notEqual",
    [lop.not_] = "not",
    [lop.and_] = "and",
    [lop.or_] = "or"
}

local unaryToName = {
    [lop.negate] = "negate",
    [lop.not_] = "not"
}

function Compiler:currentInstructionIndex()
    return #self.code
end

function Compiler:addJump(opcode, target)
    self:addCode(opcode)
    -- No target? Add placeholder.
    if target == nil then
        self:addCode(0)
        -- Will return the location of the 'zero' placeholder we just inserted.
        return self:currentInstructionIndex()
    else
        -- Jump start address is the location of the jump opcode,
        -- which is the current instruction after we add it.
        local jumpCodeToTarget = target - self:currentInstructionIndex()
        -- We need to end up at the instruction /before/ the target,
        -- because PC is incremented by one after jumps.
        self:addCode(jumpCodeToTarget - 1)
    end
end

function Compiler:fixupJump(location)
    self.code[location] = self:currentInstructionIndex() - location
end

function Compiler:addCode(opcode)
    self.code[#self.code + 1] = opcode
end

function Compiler:variableToNumber(variable)
    local number = self.variables[variable]
    if not number then
        number = self.nvars + 1
        self.nvars = number
        self.variables[variable] = number
    end
    return number
end

function Compiler:codeFunctionCall(ast)
    local func = self.functions[ast.name]
    if not func then
        error('Undefined function "' .. ast.name .. '()."')
    else
        self:addCode("callFunction")
        self:addCode(func.code)
    end
end

function Compiler:codeExpression(ast)
    if ast.tag == "number" then
        self:addCode("push")
        self:addCode(ast.value)
    elseif ast.tag == "variable" then
        if self.variables[ast.value] == nil then
            error(
                (Compiler.translate and translator.err.compileErrUndefinedVariable or
                    "Trying to load from undefined variable") ..
                    ' "' .. ast.value .. '"'
            )
        end
        self:addCode("load")
        self:addCode(self:variableToNumber(ast.value))
    elseif ast.tag == "functionCall" then
        self:codeFunctionCall(ast)
    elseif ast.tag == "arrayElement" then
        self:codeExpression(ast.array)
        self:codeExpression(ast.index)
        self:addCode("getArray")
    elseif ast.tag == "newArray" then
        self:codeExpression(ast.initialValue)
        self:codeExpression(ast.size)
        self:addCode("newArray")
    elseif ast.tag == "binaryOp" then
        if ast.op == lop.and_ then
            self:codeExpression(ast.firstChild)
            local fixupSSAnd = self:addJump("jumpIfFalseJumpNoPop")
            self:codeExpression(ast.secondChild)
            self:fixupJump(fixupSSAnd)
        elseif ast.op == lop.or_ then
            self:codeExpression(ast.firstChild)
            local fixupSSOr = self:addJump("jumpIfTrueJumpNoPop")
            self:codeExpression(ast.secondChild)
            self:fixupJump(fixupSSOr)
        else
            self:codeExpression(ast.firstChild)
            self:codeExpression(ast.secondChild)
            self:addCode(toName[ast.op])
        end
    elseif ast.tag == "unaryOp" then
        self:codeExpression(ast.child)
        if ast.op ~= "+" then
            self:addCode(unaryToName[ast.op])
        end
    else
        error('Unknown expression node tag "' .. ast.tag .. '."')
    end
end

function Compiler:codeAssignment(ast)
    local writeTarget = ast.writeTarget
    if writeTarget.tag == "variable" then
        if self.functions[ast.writeTarget.value] then
            error('Assigning to variable "' .. ast.writeTarget.value .. '" with the same name as a function.')
        end
        self:codeExpression(ast.assignment)
        self:addCode("store")
        self:addCode(self:variableToNumber(ast.writeTarget.value))
    elseif writeTarget.tag == "arrayElement" then
        self:codeExpression(ast.writeTarget.array)
        self:codeExpression(ast.writeTarget.index)
        self:codeExpression(ast.assignment)
        self:addCode("setArray")
    else
        error('Unknown write target type, tag was "' .. tostring(ast.tag) .. '."')
    end
end

function Compiler:codeStatement(ast)
    if ast.tag == "emptyStatement" then
        return
    elseif ast.tag == "statementSequence" then
        self:codeStatement(ast.firstChild)
        self:codeStatement(ast.secondChild)
    elseif ast.tag == "return" then
        self:codeExpression(ast.sentence)
        self:addCode("return")
    elseif ast.tag == "functionCall" then
        self:codeFunctionCall(ast)
        -- Discard return value for function statements, since it's not used by anything.
        self:addCode("pop")
        self:addCode(1)
    elseif ast.tag == "assignment" then
        self:codeAssignment(ast)
    elseif ast.tag == "if" then
        -- Expression and jump
        self:codeExpression(ast.expression)
        local skipIfFixup = self:addJump("jumpIfFalse")
        -- Inside of if
        self:codeStatement(ast.block)
        if ast.elseBlock then
            -- If else, we need an instruction at the end of
            -- the 'if' block to jump past the 'else' block
            local skipElseFixup = self:addJump("jump")

            -- And our target for failing the 'if' is this 'else,'
            -- so set its target here after the jump to the end of 'else.'
            self:fixupJump(skipIfFixup)
            -- Fill out the 'else'
            self:codeStatement(ast.elseBlock)

            -- Finally, set the 'skip else' jump to here, after the 'else' block
            self:fixupJump(skipElseFixup)
        else
            self:fixupJump(skipIfFixup)
        end
    elseif ast.tag == "while" then
        local whileStart = self:currentInstructionIndex()
        self:codeExpression(ast.expression)
        local skipWhileFixup = self:addJump "jumpIfFalse"
        self:codeStatement(ast.block)
        self:addJump("jump", whileStart)
        self:fixupJump(skipWhileFixup)
    elseif ast.tag == "print" then
        self:codeExpression(ast.toPrint)
        self:addCode("print")
    else
        error('Unknown statement node tag "' .. ast.tag .. '."')
    end
end

function Compiler:codeFunction(ast)
    if not ast.body then
        self.functions[ast.name] = {code = {}, forwardDeclaration = true}
        return
    end

    if self.functions[ast.name] ~= nil and not self.functions[ast.name].forwardDeclaration then
        error("Duplicate function name")
    end

    local functionCode = self.functions[ast.name] and self.functions[ast.name].code or {}
    self.functions[ast.name] = {code = functionCode}
    self.code = functionCode
    self:codeStatement(ast.body)
    if functionCode[#functionCode] ~= "return" then
        self:addCode("push")
        self:addCode(0)
        self:addCode("return")
    end
end

function module.compile(ast, translate)
    Compiler.translate = translate

    for i = 1, #ast do
        Compiler:codeFunction(ast[i])
    end

    local entryPoint = Compiler.functions[literals.entryPointName]
    if not entryPoint then
        error("No entrypoint found")
    end
    return entryPoint.code
end

return module
