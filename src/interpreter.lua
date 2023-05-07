local module = {}

local function traceUnaryOp(trace, operator, value)
    if trace then
        trace[#trace + 1] = operator .. " " .. tostring(value)
    end
end

local function traceBinaryOp(trace, operator, stack, top)
    if trace then
        trace[#trace + 1] = operator .. " " .. stack[top - 1] .. " " .. stack[top]
    end
end

local function traceTwoCodes(trace, code, pc)
    if trace then
        trace[#trace + 1] = code[pc] .. " " .. tostring(code[pc + 1])
    end
end

local function traceCustom(trace, string)
    if trace then
        trace[#trace + 1] = string
    end
end

local function popStack(stack, top, amount)
    for i = top + amount - 1, top, -1 do
        stack[top] = nil
        top = top - 1
    end
    return top
end

local function calculatePad(array)
    return 0
end

local function copyObjectNoSelfReferences(object)
    if type(object) ~= "table" then
        return object
    end
    local result = {}
    for k, v in pairs(object) do
        result[copyObjectNoSelfReferences(k)] = copyObjectNoSelfReferences(v)
    end
    return result
end

local function printValue(array, depth, pad, last, visited)
    visited = visited or {}
    if pad == nil then
        pad = calculatePad(array)
        printValue(array, depth, pad, last, visited)
        return
    end

    if type(array) ~= "table" then
        io.write(tostring(array))
        return
    end

    -- Check if the table has already been visited
    if visited[array] then
        io.write("<selfrefer>")
        return
    end

    visited[array] = true

    depth = depth or 0
    if depth > 0 then
        io.write("\n")
    end
    io.write((" "):rep(depth) .. "[")

    for i = 1, #array - 1 do
        printValue(array[i], depth + 1, pad, false, visited)
        io.write(",")
        if type(array[i]) ~= "table" then
            io.write(" ")
        end
    end
    printValue(array[#array], depth + 1, pad, true, visited)

    io.write("]")

    if last then
        io.write("\n" .. (" "):rep(depth - 1))
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
            top = popStack(stack, top, 1)
        elseif code[pc] == "subtract" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] - stack[top]
            top = popStack(stack, top, 1)
        elseif code[pc] == "multiply" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] * stack[top]
            top = popStack(stack, top, 1)
        elseif code[pc] == "divide" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] / stack[top]
            top = popStack(stack, top, 1)
        elseif code[pc] == "modulus" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] % stack[top]
            top = popStack(stack, top, 1)
        elseif code[pc] == "exponent" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] ^ stack[top]
            top = popStack(stack, top, 1)
        elseif code[pc] == "greater" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] > stack[top]
            top = popStack(stack, top, 1)
        elseif code[pc] == "less" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] < stack[top]
            top = popStack(stack, top, 1)
        elseif code[pc] == "greaterOrEqual" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] >= stack[top]
            top = popStack(stack, top, 1)
        elseif code[pc] == "lessOrEqual" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] <= stack[top]
            top = popStack(stack, top, 1)
        elseif code[pc] == "equal" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] == stack[top]
            top = popStack(stack, top, 1)
        elseif code[pc] == "notEqual" then
            traceBinaryOp(trace, code[pc], stack, top)
            stack[top - 1] = stack[top - 1] ~= stack[top]
            top = popStack(stack, top, 1)
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
            top = popStack(stack, top, 1)
        elseif code[pc] == "newArray" then
            -- We consumed our default value from the stack, then pushed ourself, so no changes to the stack size.
            traceCustom(trace, code[pc])
            -- Our size is on the top of the stack
            local size = stack[top]
            -- The default value for all our elements is the next stack element
            local defaultValue = stack[top - 1]

            local array = {size = size}
            for i = 1, size do
                array[i] = copyObjectNoSelfReferences(defaultValue)
            end

            -- We take two elements, but we are about to add one, so pop one element,
            top = popStack(stack, top, 1)
            -- then overwrite the next one!
            stack[top] = array
        elseif code[pc] == "setArray" then
            -- Which array we're getting is two elements below
            local array = stack[top - 2]
            -- The index in the array is one element below
            local index = stack[top - 1]
            -- Finally, the value we're setting to the array is at the top.
            local value = stack[top - 0]

            traceCustom(trace, code[pc] .. " " .. "[" .. index .. "] = " .. tostring(value))

            if index > array.size or index < 1 then
                error("Out of range. Array is size " .. array.size .. " but indexed at " .. index .. ".")
            end

            -- Set the array to this value
            array[index] = value

            -- Pop the three things
            top = popStack(stack, top, 3)
        elseif code[pc] == "getArray" then
            -- The array we are getting is one element below
            local array = stack[top - 1]
            -- The index we're getting from the array is at the top
            local index = stack[top - 0]

            traceCustom(trace, code[pc] .. " " .. "[" .. index .. "]")

            -- We have consumed two things, but we're about to add one:
            -- so just decrement by one to simulate popping two and pushing one.
            top = popStack(stack, top, 1)

            if index > array.size or index < 1 then
                error("Out of range. Array is size " .. array.size .. " but indexed at " .. index .. ".")
            end

            -- Set the top of the stack to the value of this index of the array.
            -- This is also now the index of where the array we loaded from was located,
            -- so it has the benefit of removing the reference to that array from the stack.
            stack[top] = array[index]
        elseif code[pc] == "jump" then
            traceTwoCodes(trace, code, pc)
            pc = pc + 1
            pc = pc + code[pc]
        elseif code[pc] == "jumpIfFalse" then
            traceTwoCodes(trace, code, pc)
            pc = pc + 1
            if not stack[top] then
                pc = pc + code[pc]
            end
            top = popStack(stack, top, 1)
        elseif code[pc] == "jumpIfFalseJumpNoPop" then
            traceTwoCodes(trace, code, pc)
            pc = pc + 1
            if not stack[top] then
                pc = pc + code[pc]
            else
                top = popStack(stack, top, 1)
            end
        elseif code[pc] == "jumpIfTrueJumpNoPop" then
            traceTwoCodes(trace, code, pc)
            pc = pc + 1
            if stack[top] then
                pc = pc + code[pc]
            else
                top = popStack(stack, top, 1)
            end
        elseif code[pc] == "print" then
            traceUnaryOp(trace, code[pc], stack[top])
            printValue(stack[top])
            io.write "\n"
            top = popStack(stack, top, 1)
        elseif code[pc] == "return" then
            traceUnaryOp(trace, code[pc], stack[top])
            -- Do it this way because return will probably not always exit the program...
            local returnValue = stack[top]
            top = popStack(stack, top, 1)
            return returnValue
        else
            error "unknown instruction"
        end
        pc = pc + 1
    end
end

return module
