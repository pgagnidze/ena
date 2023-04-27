local module = {}

local function traceUnaryOp(trace, operator, value)
    if trace then
        trace[#trace + 1] = operator .. " " .. value
    end
end

local function traceBinaryOp(trace, operator, stack, top)
    if trace then
        trace[#trace + 1] = operator .. " " .. stack[top - 1] .. " " .. stack[top]
    end
end

-- Output the code at the given pc and the next num instructions.
local function traceTwoCodes(trace, code, pc)
    if type(trace) == type({}) then
        trace[#trace + 1] = code[pc] .. " " .. code[pc + 1]
    end
end

function module.run(code, trace)
    local stack = {}
    local memory = {}
    local pc = 1
    local top = 0
    while pc <= #code do
        --[[
    io.write '--> '
    for i = 1, top do io.write(stack[i], ' ') end
    io.write '\n'
    ]]
        if code[pc] == "push" then
            traceTwoCodes(trace, code, pc)
            pc = pc + 1
            top = top + 1
            stack[top] = code[pc]
        elseif code[pc] == "add" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] + stack[top]
            top = top - 1
        elseif code[pc] == "subtract" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] - stack[top]
            top = top - 1
        elseif code[pc] == "multiply" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] * stack[top]
            top = top - 1
        elseif code[pc] == "divide" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] / stack[top]
            top = top - 1
        elseif code[pc] == "modulus" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] % stack[top]
            top = top - 1
        elseif code[pc] == "exponent" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] ^ stack[top]
            top = top - 1
        elseif code[pc] == "greater" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] > stack[top] and 1 or 0
            top = top - 1
        elseif code[pc] == "less" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] < stack[top] and 1 or 0
            top = top - 1
        elseif code[pc] == "greaterOrEqual" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] >= stack[top] and 1 or 0
            top = top - 1
        elseif code[pc] == "lessOrEqual" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] <= stack[top] and 1 or 0
            top = top - 1
        elseif code[pc] == "equal" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] == stack[top] and 1 or 0
            top = top - 1
        elseif code[pc] == "notEqual" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] ~= stack[top] and 1 or 0
            top = top - 1
        elseif code[pc] == "negate" then
            traceUnaryOp(trace, code[pc], stack[top])
            stack[top] = -stack[top]
        elseif code[pc] == "not" then
            traceUnaryOp(trace, code[pc], stack[top])
            if stack[top] == 0 then
                stack[top] = 1
            else
                stack[top] = 0
            end
        elseif code[pc] == "load" then
            traceTwoCodes(trace, code, pc)
            top = top + 1
            pc = pc + 1
            stack[top] = memory[code[pc]]
        elseif code[pc] == "store" then
            traceTwoCodes(trace, code, pc)
            pc = pc + 1
            memory[code[pc]] = stack[top]
            top = top - 1
        elseif code[pc] == "jumpIfZero" then
            traceTwoCodes(trace, code, pc)
            pc = pc + 1
            if stack[top] == 0 then
                pc = pc + code[pc]
            end
            top = top - 1
        elseif code[pc] == "jump" then
            traceTwoCodes(trace, code, pc)
            pc = pc + 1
            pc = pc + code[pc]
        elseif code[pc] == "jumpIfZeroJumpNoPop" then
            traceTwoCodes(trace, code, pc)
            pc = pc + 1
            if stack[top] == 0 then
                pc = pc + code[pc]
            else
                top = top - 1
            end
        elseif code[pc] == "jumpIfNonzeroJumpNoPop" then
            traceTwoCodes(trace, code, pc)
            pc = pc + 1
            if stack[top] ~= 0 then
                pc = pc + code[pc]
            else
                top = top - 1
            end
        elseif code[pc] == "print" then
            traceUnaryOp(trace, code[pc], stack[top])
            print(stack[top])
            top = top - 1
        elseif code[pc] == "return" then
            traceUnaryOp(trace, code[pc], stack[top])
            return stack[top]
        else
            error "unknown instruction"
        end
        pc = pc + 1
    end
end

return module
