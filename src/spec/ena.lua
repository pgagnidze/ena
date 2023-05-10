local lu = require "luaunit"
local module = {}
local entryPointName = require("literals").entryPointName

local function wrapWithEntrypoint(string)
    return "function " .. entryPointName .. "() {" .. string .. "}"
end

function module:endToEnd(input, addEntryPoint)
    input = addEntryPoint and wrapWithEntrypoint(input) or input
    local ast = module.parse(input)
    if ast == nil then
        return "Parsing failed!"
    end
    local code = module.compiler.compile(ast)
    if code == nil then
        return "Compilation failed!"
    end
    return module.interpreter.execute(code, {})
end

function module:init(parse, compiler, interpreter)
    module.parse = parse
    module.compiler = compiler
    module.interpreter = interpreter
    return module
end

function module:testAssignmentAndParentheses()
    lu.assertEquals(self:endToEnd("i = (1 + 4) * 5; return i", true), 25)
end

function module:testReturn()
    lu.assertEquals(self:endToEnd("return 10", true), 10)
end

function module:testAssignmentAndReturn()
    lu.assertEquals(self:endToEnd("i = 4 * 3; return i;", true), 12)
end

function module:testEmptyStatements()
    lu.assertEquals(self:endToEnd(";;;;", true), 0)
end

function module:testEmptyInput()
    lu.assertEquals(self:endToEnd("", true), 0)
end

function module:testStackedUnaryOperators()
    lu.assertEquals(self:endToEnd("i = - - - - 4 * 3; return i", true), 12)
end

function module:testUnaryOperators()
    lu.assertEquals(self:endToEnd("i = -4 * 3; return i", true), -12)
end

function module:testComplexSequenceResult()
    lu.assertEquals(
        self:endToEnd([[
x = 12 / 2;
y = 12 * 12 / 2;
z = x * y % 12;
z = y ^ x + z;
return z;
  ]], true),
        139314069504
    )
end

function module:testExponentPrecedence()
    lu.assertEquals(self:endToEnd("i = 2 ^ 3 ^ 2; return i", true), 512)
end

function module:testBlockAndLineComments()
    lu.assertEquals(
        self:endToEnd(
            [[
        # Start comment

        a = 10 + 4; # End of line comment

        # Block comment inside line comment: #{ blah blah blah #}

        #{
        # Comments nested in block comment
        # Another one
        b = b * 10 # Commented-out line of code
        #}
        b = a * a;
        c = a/b;

        # Disabled block comment

        ##{
        a = a * 2;
        #}
        return a;
        ]],
            true
        ),
        28
    )
end

function module:testKeywordExcludeRules()
    lu.assertEquals(module.parse(wrapWithEntrypoint "return1"), nil)
    lu.assertEquals(module.parse(wrapWithEntrypoint "a = 1; returna"), nil)
    lu.assertEquals(module.parse(wrapWithEntrypoint "return = 1"), nil)
    lu.assertEquals(module.parse(wrapWithEntrypoint "return return"), nil)
end

function module:testFullProgram()
    lu.assertEquals(
        self:endToEnd(
            [[
            # a is 14
            a = 10 + 4;
            #{
            14 * 14 - 10 = 186
            #}
            b = a * a - 10;
            # (186 + 10)/14
            c = (b + 10)/a;
            return c;
            ]],
            true
        ),
        14
    )
end

function module:testNot()
    lu.assertEquals(self:endToEnd("return ! (1.5!=0)", true), false)
    lu.assertEquals(self:endToEnd("return ! ! (167!=0)", true), true)
    lu.assertEquals(self:endToEnd("return!!!(12412.435!=0)", true), false)
end

function module:testIf()
    lu.assertEquals(
        self:endToEnd(
            [[
            a = 10 + 4;
            b = a * a - -10;
            c = a/b;
            if c < a {
              p = 24;
              c = 12;
            };
            return c;
            ]],
            true
        ),
        12
    )
end

function module:testIfElse()
    lu.assertEquals(
        self:endToEnd(
            [[
            a = 20;
            b = 10;
            if b < a {
                b = 1
            } elseif b > a {
                b = 2
            } else {
                b = 3
            };
            return b;
            ]],
            true
        ),
        1
    )
end

function module:testEmptyIfElse()
    lu.assertEquals(
        self:endToEnd(
            [[
            a = 20;
            b = a;
            if b < a {
            } elseif b > a {
            } else {
            };
            return b;
            ]],
            true
        ),
        20
    )
end

function module:testWhile()
    lu.assertEquals(
        self:endToEnd(
            [[
            a = 1;
            b = 10;
            while a < b {
                a = a + 1
            };

            return a
            ]],
            true
        ),
        10
    )
end

function module:testArrays()
    lu.assertEquals(
        self:endToEnd(
            [[
            function entrypoint() {
                array = new [2][2] 1;
                array[1][1] = 0;

                test = 0;
                test = test & array[1][2];
                test = test & array[2][1];
                test = test & array[2][2];

                return test
            }
            ]]
        ),
        1
    )
end

function module:testFunctionCall()
    lu.assertEquals(
        self:endToEnd(
            [[
            function a() {
                return 12
            }

            function entrypoint() {
                return 24 + a();
            }
            ]]
        ),
        36
    )
end

return module
