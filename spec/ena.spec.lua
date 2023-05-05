local lu = require "luaunit"
local module = {}

function module:init(parse, toStackVM, interpreter)
    module.parse = parse
    module.toStackVM = toStackVM
    module.interpreter = interpreter
    return module
end

function module:testAssignmentAndParentheses()
    local input = "i = (1 + 2) * 3"
    local ast = module.parse(input)
    local expected = {
        tag = "assignment",
        identifier = "i",
        assignment = {
            tag = "binaryOp",
            firstChild = {
                tag = "binaryOp",
                firstChild = {
                    tag = "number",
                    value = 1
                },
                op = "+",
                secondChild = {
                    tag = "number",
                    value = 2
                }
            },
            op = "*",
            secondChild = {
                tag = "number",
                value = 3
            }
        }
    }
    lu.assertEquals(ast, expected)
end

function module:testReturn()
    local input = "return 1 + 2"
    local ast = module.parse(input)
    local expected = {
        tag = "return",
        sentence = {
            tag = "binaryOp",
            firstChild = {
                tag = "number",
                value = 1
            },
            op = "+",
            secondChild = {
                tag = "number",
                value = 2
            }
        }
    }
    lu.assertEquals(ast, expected)
end

function module:testAssignmentAndReturn()
    local input = "i = 4 * 3; @ i * 64; return i;"
    local ast = module.parse(input)
    local expected = {
        tag = "statementSequence",
        firstChild = {
            tag = "assignment",
            identifier = "i",
            assignment = {
                tag = "binaryOp",
                firstChild = {
                    tag = "number",
                    value = 4
                },
                op = "*",
                secondChild = {
                    tag = "number",
                    value = 3
                }
            }
        },
        secondChild = {
            tag = "statementSequence",
            firstChild = {
                tag = "print",
                toPrint = {
                    tag = "binaryOp",
                    firstChild = {
                        tag = "variable",
                        value = "i"
                    },
                    op = "*",
                    secondChild = {
                        tag = "number",
                        value = 64
                    }
                }
            },
            secondChild = {
                tag = "return",
                sentence = {
                    tag = "variable",
                    value = "i"
                }
            }
        }
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyStatements()
    local input = ";;;;"
    local ast = module.parse(input)
    local expected = {
        tag = "emptyStatement"
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyInput()
    local input = ""
    local ast = module.parse(input)
    local expected = {
        tag = "emptyStatement"
    }
    lu.assertEquals(ast, expected)
end

function module.testStackedUnaryOperators()
    local input = "i = - - - - 4 * 3"
    local ast = module.parse(input)
    local expected = {
        tag = "assignment",
        identifier = "i",
        assignment = {
            tag = "binaryOp",
            firstChild = {
                tag = "unaryOp",
                op = "-",
                child = {
                    tag = "unaryOp",
                    op = "-",
                    child = {
                        tag = "unaryOp",
                        op = "-",
                        child = {
                            tag = "unaryOp",
                            op = "-",
                            child = {
                                tag = "number",
                                value = 4
                            }
                        }
                    }
                }
            },
            op = "*",
            secondChild = {
                tag = "number",
                value = 3
            }
        }
    }
    lu.assertEquals(ast, expected)
end

function module.testUnaryOperators()
    local input = "i = -4 * 3"
    local ast = module.parse(input)
    local expected = {
        tag = "assignment",
        identifier = "i",
        assignment = {
            tag = "binaryOp",
            firstChild = {
                tag = "unaryOp",
                op = "-",
                child = {
                    tag = "number",
                    value = 4
                }
            },
            op = "*",
            secondChild = {
                tag = "number",
                value = 3
            }
        }
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyStatementsLeadingTrailing()
    local input = ";;;;i = 4 * 3;;;;"
    local ast = module.parse(input)
    local expected = {
        tag = "assignment",
        identifier = "i",
        assignment = {
            tag = "binaryOp",
            firstChild = {
                tag = "number",
                value = 4
            },
            op = "*",
            secondChild = {
                tag = "number",
                value = 3
            }
        }
    }
    lu.assertEquals(ast, expected)
end

function module.testEmptyStatementsInterspersed()
    local input = ";;;;i = 4 * 3;;;;@ i * 64;;;;return i;;;;"
    local ast = module.parse(input)
    local expected = {
        tag = "statementSequence",
        firstChild = {
            tag = "assignment",
            identifier = "i",
            assignment = {
                tag = "binaryOp",
                firstChild = {
                    tag = "number",
                    value = 4
                },
                op = "*",
                secondChild = {
                    tag = "number",
                    value = 3
                }
            }
        },
        secondChild = {
            tag = "statementSequence",
            firstChild = {
                tag = "print",
                toPrint = {
                    tag = "binaryOp",
                    firstChild = {
                        tag = "variable",
                        value = "i"
                    },
                    op = "*",
                    secondChild = {
                        tag = "number",
                        value = 64
                    }
                }
            },
            secondChild = {
                tag = "return",
                sentence = {
                    tag = "variable",
                    value = "i"
                }
            }
        }
    }
    lu.assertEquals(ast, expected)
end

function module.testComplexSequenceResult()
    local input =
        "x value = 12 / 2;" ..
        "y value = 12 * 12 / 2;" ..
            "z value = x value * y value % 12;" .. "z value = y value ^ x value + z value;" .. "return z value;"

    local ast = module.parse(input)
    local code = module.toStackVM.translate(ast)
    local result = module.interpreter.run(code)
    lu.assertEquals(result, 139314069504)
end

function module.testExponentPrecedence()
    local input = "i = 2 ^ 3 ^ 4"
    local ast = module.parse(input)
    local expected = {
        tag = "assignment",
        identifier = "i",
        assignment = {
            tag = "binaryOp",
            firstChild = {
                tag = "number",
                value = 2
            },
            op = "^",
            secondChild = {
                tag = "binaryOp",
                firstChild = {
                    tag = "number",
                    value = 3
                },
                op = "^",
                secondChild = {
                    tag = "number",
                    value = 4
                }
            }
        }
    }
    lu.assertEquals(ast, expected)
end

function module.testBlockAndLineComments()
    local input =
        [[
# Start comment

a = 10 + 4; # End of line comment
#{#} # Single-line block comment

# Block comment inside line comment: #{ blah blah blah #}

#{
# Comments nested in block comment
# Another one
b = b * 10 # Commented-out line of code
#}
b = a * a - 10;
c = a/b;

# Disabled block comment

##{
@c;
#}
return c;
# Final comment
]]
    local ast = module.parse(input)
    local expected = {
        tag = "statementSequence",
        firstChild = {
            tag = "assignment",
            identifier = "a",
            assignment = {
                tag = "binaryOp",
                firstChild = {
                    tag = "number",
                    value = 10
                },
                op = "+",
                secondChild = {
                    tag = "number",
                    value = 4
                }
            }
        },
        secondChild = {
            tag = "statementSequence",
            firstChild = {
                tag = "assignment",
                identifier = "b",
                assignment = {
                    tag = "binaryOp",
                    firstChild = {
                        tag = "binaryOp",
                        firstChild = {
                            tag = "variable",
                            value = "a"
                        },
                        op = "*",
                        secondChild = {
                            tag = "variable",
                            value = "a"
                        }
                    },
                    op = "-",
                    secondChild = {
                        tag = "number",
                        value = 10
                    }
                }
            },
            secondChild = {
                tag = "statementSequence",
                firstChild = {
                    tag = "assignment",
                    identifier = "c",
                    assignment = {
                        tag = "binaryOp",
                        firstChild = {
                            tag = "variable",
                            value = "a"
                        },
                        op = "/",
                        secondChild = {
                            tag = "variable",
                            value = "b"
                        }
                    }
                },
                secondChild = {
                    tag = "statementSequence",
                    firstChild = {
                        tag = "print",
                        toPrint = {
                            tag = "variable",
                            value = "c"
                        }
                    },
                    secondChild = {
                        tag = "return",
                        sentence = {
                            tag = "variable",
                            value = "c"
                        }
                    }
                }
            }
        }
    }
    lu.assertEquals(ast, expected)
end

function module.testKeywordExcludeRules()
    lu.assertEquals(module.parse("return1"), nil)
    lu.assertEquals(module.parse("a = 1; returna"), nil)
    lu.assertEquals(module.parse("return = 1"), nil)
    lu.assertEquals(module.parse("return return"), nil)
    lu.assertEquals(
        module.parse("delta x = 1; return delta x"),
        {
            tag = "statementSequence",
            firstChild = {
                tag = "assignment",
                identifier = "delta x",
                assignment = {
                    tag = "number",
                    value = 1
                }
            },
            secondChild = {
                tag = "return",
                sentence = {
                    tag = "variable",
                    value = "delta x"
                }
            }
        }
    )
    lu.assertEquals(
        module.parse("return of the variable = 1; return return of the variable"),
        {
            tag = "statementSequence",
            firstChild = {
                tag = "assignment",
                identifier = "return of the variable",
                assignment = {
                    tag = "number",
                    value = 1
                }
            },
            secondChild = {
                tag = "return",
                sentence = {
                    tag = "variable",
                    value = "return of the variable"
                }
            }
        }
    )
end

function module.testFullProgram()
    local input =
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
]]
    local ast = module.parse(input)
    local code = module.toStackVM.translate(ast)
    local result = module.interpreter.run(code)
    lu.assertEquals(result, 14)
end

function module.testLessonFourCornerCases()
    lu.assertEquals(
        module.parse "returned = 10",
        {
            tag = "assignment",
            identifier = "returned",
            assignment = {
                tag = "number",
                value = 10
            }
        }
    )
    lu.assertEquals(module.parse "x=10y=20", nil)

    lu.assertEquals(module.parse([[
      x=1;
      returnx
    ]]), nil)

    lu.assertEquals(module.parse([[
      #{
      bla bla
    ]]), nil)

    lu.assertEquals(module.parse "#{##}", {tag = "emptyStatement"})

    lu.assertEquals(module.parse "#{#{#}", {tag = "emptyStatement"})

    lu.assertEquals(module.parse([[
      #{
      x=1
      #}
    ]]), {tag = "emptyStatement"})

    lu.assertEquals(
        module.parse([[
      #{#}x=1;
      return x
    ]]),
        {
            tag = "statementSequence",
            firstChild = {
                tag = "assignment",
                identifier = "x",
                assignment = {
                    tag = "number",
                    value = 1
                }
            },
            secondChild = {
                tag = "return",
                sentence = {
                    tag = "variable",
                    value = "x"
                }
            }
        }
    )

    lu.assertEquals(
        module.parse([[
      #{#} x=10; #{#}
      return x
    ]]),
        {
            tag = "statementSequence",
            firstChild = {
                tag = "assignment",
                identifier = "x",
                assignment = {
                    tag = "number",
                    value = 10
                }
            },
            secondChild = {
                tag = "return",
                sentence = {
                    tag = "variable",
                    value = "x"
                }
            }
        }
    )
    lu.assertEquals(
        module.parse([[
        ##{
        x=10
        #}
        ]]),
        {
            tag = "assignment",
            identifier = "x",
            assignment = {
                tag = "number",
                value = 10
            }
        }
    )
end

function module.testNot()
    local ast = module.parse("return ! 1.5")
    lu.assertEquals(
        ast,
        {
            tag = "return",
            sentence = {
                tag = "unaryOp",
                op = "!",
                child = {
                    tag = "number",
                    value = 1.5
                }
            }
        }
    )
    local code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 0)

    local ast = module.parse("return ! ! 167")
    lu.assertEquals(
        ast,
        {
            tag = "return",
            sentence = {
                tag = "unaryOp",
                op = "!",
                child = {
                    tag = "unaryOp",
                    op = "!",
                    child = {
                        tag = "number",
                        value = 167
                    }
                }
            }
        }
    )
    local code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 1)

    local ast = module.parse("return!!!12412.435")
    lu.assertEquals(
        ast,
        {
            tag = "return",
            sentence = {
                tag = "unaryOp",
                op = "!",
                child = {
                    tag = "unaryOp",
                    op = "!",
                    child = {
                        tag = "unaryOp",
                        op = "!",
                        child = {
                            tag = "number",
                            value = 12412.435
                        }
                    }
                }
            }
        }
    )
    local code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 0)
end

function module.testIf()
    local code =
        [[
a = 10 + 4;
b = a * a - -10;
c = a/b;
if c < a {
  this is a long name = 24;
  c = 12;
};
return c;
]]
    local ast = module.parse(code)
    lu.assertEquals(
        ast,
        {
            tag = "statementSequence",
            firstChild = {
                tag = "assignment",
                identifier = "a",
                assignment = {
                    tag = "binaryOp",
                    firstChild = {
                        tag = "number",
                        value = 10
                    },
                    op = "+",
                    secondChild = {
                        tag = "number",
                        value = 4
                    }
                }
            },
            secondChild = {
                tag = "statementSequence",
                firstChild = {
                    tag = "assignment",
                    identifier = "b",
                    assignment = {
                        tag = "binaryOp",
                        firstChild = {
                            tag = "binaryOp",
                            firstChild = {
                                tag = "variable",
                                value = "a"
                            },
                            op = "*",
                            secondChild = {
                                tag = "variable",
                                value = "a"
                            }
                        },
                        op = "-",
                        secondChild = {
                            tag = "unaryOp",
                            op = "-",
                            child = {
                                tag = "number",
                                value = 10
                            }
                        }
                    }
                },
                secondChild = {
                    tag = "statementSequence",
                    firstChild = {
                        tag = "assignment",
                        identifier = "c",
                        assignment = {
                            tag = "binaryOp",
                            firstChild = {
                                tag = "variable",
                                value = "a"
                            },
                            op = "/",
                            secondChild = {
                                tag = "variable",
                                value = "b"
                            }
                        }
                    },
                    secondChild = {
                        tag = "statementSequence",
                        firstChild = {
                            tag = "if",
                            expression = {
                                tag = "binaryOp",
                                firstChild = {
                                    tag = "variable",
                                    value = "c"
                                },
                                op = "<",
                                secondChild = {
                                    tag = "variable",
                                    value = "a"
                                }
                            },
                            block = {
                                tag = "statementSequence",
                                firstChild = {
                                    tag = "assignment",
                                    identifier = "this is a long name",
                                    assignment = {
                                        tag = "number",
                                        value = 24
                                    }
                                },
                                secondChild = {
                                    tag = "assignment",
                                    identifier = "c",
                                    assignment = {
                                        tag = "number",
                                        value = 12
                                    }
                                }
                            }
                        },
                        secondChild = {
                            tag = "return",
                            sentence = {
                                tag = "variable",
                                value = "c"
                            }
                        }
                    }
                }
            }
        }
    )
    local code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 12)
end

function module.testIfElseElseIf()
    local ifOnlyYes = [[
a = 20;
b = 10;
if b < a {
  b = 1
};
return b;
]]

    local ast = module.parse(ifOnlyYes)
    local code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 1)

    local ifOnlyNo = [[
  a = 20;
  b = 100;
  if b < a {
    b = 1
  };
  return b;
  ]]

    ast = module.parse(ifOnlyNo)
    code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 100)

    local ifElseYes = [[
a = 20;
b = 10;
if b < a {
  b = 1
} else {
  b = 2
};
return b;
]]

    ast = module.parse(ifElseYes)
    code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 1)

    local ifElseNo = [[
  a = 20;
  b = 100;
  if b < a {
    b = 1
  } else {
    b = 2
  };
  return b;
  ]]

    ast = module.parse(ifElseNo)
    code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 2)

    local ifElseIfYes = [[
a = 20;
b = 10;
if b < a {
  b = 1
} elseif b > a {
  b = 2
};
return b;
]]

    ast = module.parse(ifElseIfYes)
    code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 1)

    local ifElseIfNo = [[
  a = 20;
  b = 100;
  if b < a {
    b = 1
  } elseif b > a {
    b = 2
  };
  return b;
  ]]

    ast = module.parse(ifElseIfNo)
    code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 2)

    local ifElseIfNeither = [[
a = 20;
b = a;
if b < a {
  b = 1
} elseif b > a {
  b = 2
};
return b;
]]

    ast = module.parse(ifElseIfNeither)
    code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 20)
    local firstClause = [[
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
]]
    ast = module.parse(firstClause)
    code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 1)

    local secondClause =
        [[
a = 20;
b = 100;
if b < a {
  b = 1
} elseif b > a {
  b = 2
} else {
  b = 3
};
return b;
]]
    ast = module.parse(secondClause)
    code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 2)
    local thirdClause = [[
a = 20;
b = a;
if b < a {
b = 1
} elseif b > a {
b = 2
} else {
b = 3
};
return b;
  ]]

    ast = module.parse(thirdClause)
    code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 3)

    local empty = [[
a = 20;
b = a;
if b < a {
} elseif b > a {
} else {
};
return b;
  ]]

    ast = module.parse(empty)
    code = module.toStackVM.translate(ast)
    lu.assertEquals(module.interpreter.run(code), 20)
end

return module
