local module = {}
local translator = require "ena.lang.translator"
local literals = require "ena.lang.literals"
local lop = literals.op

local Compiler = {}

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

function Compiler:new(o)
    o =
        o or
        {
            functions = {},
            variables = {},
            nvars = 0,
            locals = {},
            blockBases = {[0] = 0}
        }
    self.__index = self
    setmetatable(o, self)
    return o
end

function Compiler:findLocal(name)
    local loc = self.locals
    for i = #loc, 1, -1 do
        if name == loc[i] then
            return i
        end
    end
    local params = self.params
    for i = 1, #params do
        if name == params[i] then
            return -(#params - i)
        end
    end
    return nil
end

function Compiler:currentInstructionIndex()
    return #self.code
end

function Compiler:addJump(opcode, target)
    self:addCode(opcode)
    -- Add placeholder.
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
        error(
            (self.translate and translator.err.compileErrUndefinedFunction or "Undefined function") ..
                ' "' .. ast.name .. '()"'
        )
    end
    local args = ast.args
    local hasDefault = next(func.defaultArgument) ~= nil
    if #func.params == #args then
        for i = 1, #args do
            self:codeExpression(args[i])
        end
    elseif hasDefault and #func.params == #args + 1 then
        for i = 1, #args - 1 do
            self:codeExpression(args[i])
        end
        self:codeExpression(func.defaultArgument)
    else
        error(
            (self.translate and translator.err.compileErrWrongNumberOfArguments or
                "Wrong number of arguments for function") ..
                ' "' .. ast.name .. '()"'
        )
    end
    self:addCode("callFunction")
    self:addCode(func.code)
end

function Compiler:codeExpression(ast)
    if ast.tag == "number" or ast.tag == "boolean" or ast.tag == "string" then
        self:addCode("push")
        self:addCode(ast.value)
    elseif ast.tag == "nil" then
        self:addCode("pushNil")
    elseif ast.tag == "variable" then
        local idx = self:findLocal(ast.value)
        if idx then
            self:addCode("loadLocal")
            self:addCode(idx)
        elseif self.variables[ast.value] then
            self:addCode("load")
            self:addCode(self:variableToNumber(ast.value))
        else
            error(
                (self.translate and translator.err.compileErrUndefinedVariable or
                    "Trying to load from undefined variable") ..
                    ' "' .. ast.value .. '"'
            )
        end
    elseif ast.tag == "functionCall" then
        self:codeFunctionCall(ast)
    elseif ast.tag == "exec" then
        self:codeExpression(ast.command)
        self:addCode("exec")
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
            error(
                (self.translate and translator.err.compileErrVariableSameNameAsFunction or
                    "Assigning to variable with the same name as a function") ..
                    ' "' .. ast.writeTarget.value .. '"'
            )
        end
        if ast.assignment then
            self:codeExpression(ast.assignment)
        else
            self:addCode("pushNil")
        end
        local idx = self:findLocal(ast.writeTarget.value)
        if idx then
            self:addCode("storeLocal")
            self:addCode(idx)
        else
            self:addCode("store")
            self:addCode(self:variableToNumber(ast.writeTarget.value))
        end
    elseif writeTarget.tag == "arrayElement" then
        self:codeExpression(ast.writeTarget.array)
        self:codeExpression(ast.writeTarget.index)
        self:codeExpression(ast.assignment)
        self:addCode("setArray")
    else
        error('Unknown write target type, tag was "' .. tostring(ast.tag) .. '."')
    end
end

function Compiler:codeBlock(ast)
    local oldlevel = #self.locals
    self.blockBases[#self.blockBases + 1] = oldlevel + 1
    self:codeStatement(ast.body)
    self.blockBases[#self.blockBases] = nil
    local diff = #self.locals - oldlevel
    if diff > 0 then
        for i = 1, diff do
            table.remove(self.locals)
        end
        self:addCode("pop")
        self:addCode(diff)
    end
end

function Compiler:codeStatement(ast)
    if ast.tag == "emptyStatement" then
        return
    elseif ast.tag == "block" then
        self:codeBlock(ast)
    elseif ast.tag == "statementSequence" then
        self:codeStatement(ast.firstChild)
        self:codeStatement(ast.secondChild)
    elseif ast.tag == "return" then
        self:codeExpression(ast.sentence)
        self:addCode("return")
        self:addCode(#self.locals + #self.params)
    elseif ast.tag == "functionCall" then
        self:codeFunctionCall(ast)
        self:addCode("pop")
        self:addCode(1)
    elseif ast.tag == "assignment" then
        self:codeAssignment(ast)
    elseif ast.tag == "local" then
        local oldLevel = #self.locals
        for i = oldLevel, self.blockBases[#self.blockBases], -1 do
            if self.locals[i] == ast.name then
                error(
                    (self.translate and translator.err.compileErrVariableAlreadyDefined or
                        "Variable already defined in this scope") ..
                        ' "' .. ast.name .. '"'
                )
            end
        end
        if ast.init then
            self:codeExpression(ast.init)
        else
            self:addCode("pushNil")
        end
        self.locals[#self.locals + 1] = ast.name
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
    elseif ast.tag == "exec" then
        self:codeExpression(ast.command)
        self:addCode("exec")
    else
        error('Unknown statement node tag "' .. ast.tag .. '."')
    end
end

function Compiler:findFirstDuplicateParam(ast)
    local params = self.functions[ast.name].params
    local seen = {}
    for _, value in pairs(params) do
        if seen[value] then
            return value
        else
            seen[value] = true
        end
    end
    return nil
end

function Compiler:codeFunction(ast)
    if not ast.block then
        if not self.functions[ast.name] then
            self.functions[ast.name] = {code = {}, forwardDeclaration = true}
        end
    end
    local functionCode = self.functions[ast.name] and self.functions[ast.name].code or {}
    if #functionCode > 0 and not self.functions[ast.name].forwardDeclaration then
        error(
            (self.translate and translator.err.compileErrDuplicateFunctionName or "Duplicate function name") ..
                ' "' .. ast.name .. '()"'
        )
    end
    self.functions[ast.name] = {code = functionCode, params = ast.params, defaultArgument = ast.defaultArgument}
    self.code = functionCode
    self.params = ast.params
    local firstDuplicate = self:findFirstDuplicateParam(ast)
    if firstDuplicate then
        error(
            (self.translate and translator.err.compileErrDuplicateParamName or "Duplicate parameter name") ..
                ' "' .. firstDuplicate .. '"'
        )
    end
    self:codeStatement(ast.block)
    if functionCode[#functionCode] ~= "return" then
        self:addCode("pushNil")
        self:addCode("return")
        self:addCode(#self.locals + #self.params)
    end
end

function Compiler:compile(ast)
    for i = 1, #ast do
        self:codeFunction(ast[i])
    end
    local entryPoint = self.functions[literals.entryPointName]
    if not entryPoint then
        error(self.translate and translator.err.compileErrNoEntryPointFound or "No entrypoint found")
    end

    if #entryPoint.params > 0 then
        error(
            self.translate and translator.err.compileErrEntryPointParams or "Entrypoint function cannot have parameters"
        )
    end
    return entryPoint.code
end

function module.compile(ast, translate)
    local compiler = Compiler:new()
    compiler.translate = translate
    return compiler:compile(ast)
end

return module
