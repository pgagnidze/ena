local module = {}
local literals = require "literals"
local translator = require "translator"
local op = literals.op

local Compiler = {
    code = {},
    variables = {},
    nvars = 0,
    translate = false
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
    local code = self.code
    code[#code + 1] = opcode
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

function Compiler:codeExpression(ast)
    if ast.tag == "number" then
        self:addCode("push")
        self:addCode(ast.value)
    elseif ast.tag == "variable" then
        if self.variables[ast.value] == nil then
            error((Compiler.translate and translator.err.undefinedVariable or 'Trying to load from undefined variablex') .. ' "' .. ast.value .. '."')
        end
        self:addCode("load")
        self:addCode(self:variableToNumber(ast.value))
    elseif ast.tag == "binaryOp" then
        if ast.op == literals.op.and_ then
            self:codeExpression(ast.firstChild)
            local fixupSSAnd = self:addJump("jumpIfZeroJumpNoPop")
            self:codeExpression(ast.secondChild)
            self:fixupJump(fixupSSAnd)
        elseif ast.op == literals.op.or_ then
            self:codeExpression(ast.firstChild)
            local fixupSSOr = self:addJump("jumpIfNonzeroJumpNoPop")
            self:codeExpression(ast.secondChild)
            self:fixupJump(fixupSSOr)
        else
            self:codeExpression(ast.firstChild)
            self:codeExpression(ast.secondChild)
            self:addCode(op.toName[ast.op])
        end
    elseif ast.tag == "unaryOp" then
        self:codeExpression(ast.child)
        if ast.op ~= "+" then
            self:addCode(op.unaryToName[ast.op])
        end
    else
        error "invalid tree"
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
    elseif ast.tag == "assignment" then
        self:codeExpression(ast.assignment)
        self:addCode("store")
        self:addCode(self:variableToNumber(ast.identifier))
    elseif ast.tag == "if" then
        -- Expression and jump
        self:codeExpression(ast.expression)
        local skipIfFixup = self:addJump("jumpIfZero")
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
        local skipWhileFixup = self:addJump "jumpIfZero"
        self:codeStatement(ast.block)
        self:addJump("jump", whileStart)
        self:fixupJump(skipWhileFixup)
    elseif ast.tag == "print" then
        self:codeExpression(ast.toPrint)
        self:addCode("print")
    else
        error "invalid tree"
    end
end

function module.compile(ast, translate)
    Compiler.code = {}
    Compiler.variables = {}
    Compiler.nvars = 0
    Compiler.translate = translate
    Compiler:codeStatement(ast)
    Compiler:addCode("push")
    Compiler:addCode(0)
    Compiler:addCode("return")
    return Compiler.code
end

return module
