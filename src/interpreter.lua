local module = {}
local translator = require "translator"
local common = require("common")

local Interpreter = {}

function Interpreter:new(o)
    o =
        o or
        {
            errors = {},
            stack = {},
            top = 0,
            memory = {}
        }
    self.__index = self
    setmetatable(o, self)
    return o
end

local function calculatePad(array)
    return 0
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

function Interpreter:traceUnaryOp(operator)
    if self.trace then
        self.trace[#self.trace + 1] = operator .. " " .. tostring(self.stack[self.top])
    end
end

function Interpreter:traceBinaryOp(operator)
    if self.trace then
        self.trace[#self.trace + 1] = operator .. " " .. self.stack[self.top - 1] .. " " .. self.stack[self.top]
    end
end

function Interpreter:traceTwoCodes(code, pc)
    if self.trace then
        self.trace[#self.trace + 1] = code[pc] .. " " .. tostring(code[pc + 1])
    end
end

function Interpreter:traceTwoCodesAndStack(code, pc)
    if self.trace then
        self.trace[#self.trace + 1] = code[pc] .. " " .. tostring(code[pc + 1]) .. " " .. tostring(self.stack[self.top])
    end
end

function Interpreter:traceCustom(string)
    if self.trace then
        self.trace[#self.trace + 1] = string
    end
end

function Interpreter:traceStack()
    if self.trace then
        local result = {}
        for k, v in ipairs(self.stack) do
            result[k] = v
        end

        self.trace.stack[#self.trace] = result
    end
end

function Interpreter:popStack(amount)
    for i = self.top + amount - 1, self.top, -1 do
        self.stack[self.top] = nil
        self.top = self.top - 1
    end
end

function Interpreter:run(code)
    local pc = 1
    while pc <= #code do
        --[[
      io.write "--> "
      for i = 1, self.top do io.write(self.stack[i], " ") end
      io.write("\n", code[pc], "\n")
      --]]
        if code[pc] == "push" then
            self:traceTwoCodes(code, pc)
            pc = pc + 1
            self.top = self.top + 1
            self.stack[self.top] = code[pc]
        elseif code[pc] == "pop" then
            self:traceTwoCodes(code, pc)
            pc = pc + 1
            self:popStack(code[pc])
        elseif code[pc] == "add" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] + self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "subtract" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] - self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "multiply" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] * self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "divide" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] / self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "modulus" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] % self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "exponent" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] ^ self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "greater" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] > self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "less" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] < self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "greaterOrEqual" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] >= self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "lessOrEqual" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] <= self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "equal" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] == self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "notEqual" then
            self:traceBinaryOp(code[pc])
            self.stack[self.top - 1] = self.stack[self.top - 1] ~= self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "negate" then
            self:traceUnaryOp(code[pc])
            self.stack[self.top] = -self.stack[self.top]
        elseif code[pc] == "not" then
            self:traceUnaryOp(code[pc])
            self.stack[self.top] = not self.stack[self.top]
        elseif code[pc] == "load" then
            self:traceTwoCodes(code, pc)
            self.top = self.top + 1
            pc = pc + 1
            self.stack[self.top] = self.memory[code[pc]]
        elseif code[pc] == "store" then
            self:traceTwoCodesAndStack(code, pc)
            pc = pc + 1
            self.memory[code[pc]] = self.stack[self.top]
            self:popStack(1)
        elseif code[pc] == "newArray" then
            -- We consumed our default value from the stack, then pushed ourself, so no changes to the stack size.
            self:traceCustom(code[pc])
            -- Our size is on the top of the stack
            local size = self.stack[self.top]
            -- The default value for all our elements is the next stack element
            local defaultValue = self.stack[self.top - 1]

            local array = {size = size}
            for i = 1, size do
                array[i] = common.copyObjectNoSelfReferences(defaultValue)
            end

            -- We take two elements, but we are about to add one, so pop one element,
            self:popStack(1)
            -- then overwrite the next one!
            self.stack[self.top] = array
        elseif code[pc] == "setArray" then
            -- Which array we're getting is two elements below
            local array = self.stack[self.top - 2]
            -- The index in the array is one element below
            local index = self.stack[self.top - 1]
            -- Finally, the value we're setting to the array is at the top.
            local value = self.stack[self.top - 0]

            self:traceCustom(code[pc] .. " " .. "[" .. index .. "] = " .. tostring(value))

            if index > array.size or index < 1 then
                error(
                    (self.translate and translator.err.runtimeErrOutOfRangeFirst or "Out of range. Array is size") ..
                        " " ..
                            array.size ..
                                " " ..
                                    (self.translate and translator.err.runtimeErrOutOfRangeSecond or "but indexed at") ..
                                        " " .. index .. "."
                )
            end

            -- Set the array to this value
            array[index] = value

            -- Pop the three things
            self:popStack(3)
        elseif code[pc] == "getArray" then
            -- The array we are getting is one element below
            local array = self.stack[self.top - 1]
            -- The index we're getting from the array is at the top
            local index = self.stack[self.top - 0]

            self:traceCustom(code[pc] .. " " .. "[" .. index .. "]")

            -- We have consumed two things, but we're about to add one:
            -- so just decrement by one to simulate popping two and pushing one.
            self:popStack(1)

            if index > array.size or index < 1 then
                error(
                    (self.translate and translator.err.runtimeErrOutOfRangeFirst or "Out of range. Array is size") ..
                        " " ..
                            array.size ..
                                " " ..
                                    (self.translate and translator.err.runtimeErrOutOfRangeSecond or "but indexed at") ..
                                        " " .. index .. "."
                )
            end

            -- Set the top of the stack to the value of this index of the array.
            -- This is also now the index of where the array we loaded from was located,
            -- so it has the benefit of removing the reference to that array from the stack.
            self.stack[self.top] = array[index]
        elseif code[pc] == "jump" then
            self:traceTwoCodes(code, pc)
            pc = pc + 1
            pc = pc + code[pc]
        elseif code[pc] == "jumpIfFalse" then
            self:traceTwoCodesAndStack(code, pc)
            pc = pc + 1
            if not self.stack[self.top] then
                pc = pc + code[pc]
            end
            self:popStack(1)
        elseif code[pc] == "jumpIfFalseJumpNoPop" then
            self:traceTwoCodesAndStack(code, pc)
            pc = pc + 1
            if not self.stack[self.top] then
                pc = pc + code[pc]
            else
                self:popStack(1)
            end
        elseif code[pc] == "jumpIfTrueJumpNoPop" then
            self:traceTwoCodesAndStack(code, pc)
            pc = pc + 1
            if self.stack[self.top] then
                pc = pc + code[pc]
            else
                self:popStack(1)
            end
        elseif code[pc] == "print" then
            self:traceUnaryOp(code[pc])
            printValue(self.stack[self.top])
            io.write "\n"
            self:popStack(1)
        elseif code[pc] == "return" then
            self:traceUnaryOp(code[pc])
            return
        elseif code[pc] == "callFunction" then
            self:traceCustom(code[pc])
            self:traceStack()
            pc = pc + 1
            self:run(code[pc])
        else
            error("unknown instruction " .. code[pc] .. " at " .. pc)
        end
        self:traceStack()
        pc = pc + 1
    end
end

function Interpreter:execute(code)
    self:run(code)
    return self.stack[self.top]
end

function module.execute(code, trace, translate)
    local interpreter = Interpreter:new()
    trace.stack = {}
    interpreter.trace = trace
    interpreter.translate = translate
    return interpreter:execute(code)
end

return module
