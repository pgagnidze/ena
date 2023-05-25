local module = {}
local lu = require "luaunit"
local entryPointName = require("ena.lang.literals").entryPointName

local function wrapWithEntrypoint(string)
    return "function " .. entryPointName .. "() {" .. string .. "}"
end

function module:endToEnd(input, addEntryPoint)
    input = addEntryPoint and wrapWithEntrypoint(input) or input
    local ast = module.parse(input)
    if ast == nil then
        return "Parsing failed"
    end
    local code = module.compiler.compile(ast)
    return module.interpreter.execute(code, {})
end

function module:init(parse, compiler, interpreter)
    module.parse = parse
    module.compiler = compiler
    module.interpreter = interpreter
    return module
end

function module:testIdentifiers()
    local tests = {
        {input = "_leading_underscore", expected = 1},
        {input = "has spaces", expected = "Parsing failed"},
        {input = "has-hyphens", expected = "Parsing failed"},
        {input = "წერე_ქართულად", expected = 1},
        {input = "0not valid", expected = "Parsing failed"}
    }
    for i, testCase in ipairs(tests) do
        lu.assertEquals(
            self:endToEnd(testCase.input .. " = 1; return " .. testCase.input, true),
            testCase.expected,
            "Test case " .. i .. " failed"
        )
    end
end

function module:testNaturalNumbers()
    local tests = {
        {input = "0", expected = 0},
        {input = "100", expected = 100},
        {input = "1 000", expected = 1000},
        {input = "1 2 3 4 5 6", expected = 123456}
    }
    for i, testCase in ipairs(tests) do
        lu.assertEquals(
            self:endToEnd("return " .. testCase.input, true),
            testCase.expected,
            "Test case " .. i .. " failed"
        )
    end
end

function module:testRationalNumbers()
    local tests = {
        {input = "0.", expected = 0},
        {input = "0.0", expected = 0},
        {input = "0.01", expected = 0.01},
        {input = ".1", expected = 0.1},
        {input = ".01", expected = 0.01},
        {input = "1.", expected = 1},
        {input = "10.", expected = 10}
    }
    for i, testCase in ipairs(tests) do
        lu.assertEquals(
            self:endToEnd("return " .. testCase.input, true),
            testCase.expected,
            "Test case " .. i .. " failed"
        )
    end
end

function module:testExponents()
    local tests = {
        {input = "1e0", expected = 1},
        {input = "1e2", expected = 100},
        {input = "1e+0", expected = 1},
        {input = "1e+2", expected = 100},
        {input = "1e-1", expected = 0.1},
        {input = "1e-2", expected = 0.01}
    }
    for i, testCase in ipairs(tests) do
        lu.assertEquals(
            self:endToEnd("return " .. testCase.input, true),
            testCase.expected,
            "Test case " .. i .. " failed"
        )
    end
end

function module:testRationalExponents()
    local tests = {
        {input = "1.01e0", expected = 1.01},
        {input = "1.03e2", expected = 103},
        {input = "1.05e+1", expected = 10.5},
        {input = "1.06e+2", expected = 106},
        {input = "1.07e-1", expected = 0.107},
        {input = "1.09e-3", expected = 0.00109}
    }
    for i, testCase in ipairs(tests) do
        lu.assertEquals(
            self:endToEnd("return " .. testCase.input, true),
            testCase.expected,
            "Test case " .. i .. " failed"
        )
    end
end

function module:testBaseNumber()
    local tests = {
        {input = "01 0", expected = 0},
        {input = "01 1", expected = 1},
        {input = "01 10", expected = 2},
        {input = "01 11", expected = 3},
        {input = "01 100", expected = 4},
        {input = "01 101", expected = 5},
        {input = "01 110", expected = 6},
        {input = "01 111", expected = 7},
        {input = "01 1000", expected = 8},
        {input = "01 1001", expected = 9},
        {input = "01 1010", expected = 10},
        {input = "01 1011", expected = 11},
        {input = "01 1100", expected = 12},
        {input = "01 1101", expected = 13},
        {input = "01 1110", expected = 14},
        {input = "01 1111", expected = 15}
    }
    for i, testCase in ipairs(tests) do
        lu.assertEquals(
            self:endToEnd("return " .. testCase.input, true),
            testCase.expected,
            "Test case " .. i .. " failed"
        )
    end
end

function module:testBaseTwelveNumbers()
    local tests = {
        {input = "0B 0", expected = 0},
        {input = "0B 1", expected = 1},
        {input = "0B 2", expected = 2},
        {input = "0B 3", expected = 3},
        {input = "0B 4", expected = 4},
        {input = "0B 5", expected = 5},
        {input = "0B 6", expected = 6},
        {input = "0B 7", expected = 7},
        {input = "0B 8", expected = 8},
        {input = "0B 9", expected = 9},
        {input = "0B A", expected = 10},
        {input = "0B B", expected = 11},
        {input = "0B 10", expected = 12}
    }
    for i, testCase in ipairs(tests) do
        lu.assertEquals(
            self:endToEnd("return " .. testCase.input, true),
            testCase.expected,
            "Test case " .. i .. " failed"
        )
    end
end

function module:testUnaryNumbers()
    local tests = {
        {input = "00 1", expected = 1},
        {input = "00 11", expected = 2},
        {input = "00 111", expected = 3},
        {input = "00 1111", expected = 4},
        {input = "00 11111", expected = 5},
        {input = "00 11111 1", expected = 6},
        {input = "00 11111 11", expected = 7},
        {input = "00 11111 111", expected = 8}
    }
    for i, testCase in ipairs(tests) do
        lu.assertEquals(
            self:endToEnd("return " .. testCase.input, true),
            testCase.expected,
            "Test case " .. i .. " failed"
        )
    end
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
    lu.assertEquals(self:endToEnd(";;;;", true), nil)
end

function module:testEmptyInput()
    lu.assertEquals(self:endToEnd("", true), nil)
end

function module:testStackedUnaryOperators()
    lu.assertEquals(self:endToEnd("i = - - - - 4 * 3; return i", true), 12)
end

function module:testUnaryOperators()
    lu.assertEquals(self:endToEnd("i = -4 * 3; return i", true), -12)
end

function module:testComplexSequenceResult()
    lu.assertEquals(
        self:endToEnd(
            [[
            x = 12 / 2;
            y = 12 * 12 / 2;
            z = x * y % 12;
            z = y ^ x + z;
            return z;
            ]],
            true
        ),
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
    local tests = {
        {input = "return1 = 1; return return1", expected = 1},
        {input = "a = 1; returna", expected = nil},
        {input = "return = 1", expected = "Parsing failed"},
        {input = "return return", expected = "Parsing failed"}
    }
    for i, testCase in ipairs(tests) do
        lu.assertEquals(
            self:endToEnd(testCase.input, true),
            testCase.expected,
            "Test case " .. i .. " failed"
        )
    end
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

function module:testBoolean()
    lu.assertEquals(
        self:endToEnd(
            [[
            function main() {
                local a = true;
                return !a
            }
            ]]
        ),
        false
    )
end

function module:testArrays()
    lu.assertEquals(
        self:endToEnd(
            [[
            function main() {
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
            function main() {
                return 24 + a();
            }
            ]]
        ),
        36
    )
end

function module:testFunctionFactorial()
    lu.assertEquals(
        self:endToEnd(
            [[
            function fact(n = 4) {
                if n != 0 {
                    return n * fact(n - 1)
                } else {
                    return 1
                }
            }
            function main() {
                return fact()
            }
            ]]
        ),
        24
    )
end

function module:testStringLiterals()
    lu.assertEquals(
        self:endToEnd(
            [[
            function a() {
                str = "string ";
                return str
            }
            function main() {
                return a() + "literals";
            }
            ]]
        ),
        "string literals"
    )
end

function module:testStringLiteralsReturn()
    lu.assertEquals(
        self:endToEnd(
            [[
            function a() {
                return "string "
            }
            function main() {
                return a() + "literals";
            }
            ]]
        ),
        "string literals"
    )
end

function module:testNilValues()
    lu.assertEquals(
        self:endToEnd(
            [[
            function a() {
                b;
                return b
            }
            function main() {
                return a();
            }
            ]]
        ),
        nil
    )
end

function module:testShellExec()
    lu.assertEquals(
        self:endToEnd(
            [[
            function main() {
                return $ 'echo "Hello World"'
            }
            ]]
        ),
        "Hello World"
    )
end

return module
