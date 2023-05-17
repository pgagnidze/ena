local module = {op = {}, delim = {}, sep = {}, comments = {}}

--  entrypoint --
module.entryPointName = "main"

--  operators --
module.op.assign = "="
module.op.print = "@"

-- binary operators --
module.op.add = "+"
module.op.subtract = "-"
module.op.multiply = "*"
module.op.divide = "/"
module.op.modulus = "%"
module.op.exponent = "^"
module.op.less = "<"
module.op.greater = ">"
module.op.lessOrEqual = "<="
module.op.greaterOrEqual = ">="
module.op.equal = "=="
module.op.notEqual = "!="
module.op.and_ = "&"
module.op.or_ = "|"

-- unary operators --
module.op.not_ = "!"
module.op.positive = "+"
module.op.negate = "-"

--  comments --
module.comments.startLine = "#"
module.comments.openBlock = "#{"
module.comments.closeBlock = "#}"

--  delimiters --
module.delim.openArray = "["
module.delim.closeArray = "]"
module.delim.openFactor = "("
module.delim.closeFactor = ")"
module.delim.openBlock = "{"
module.delim.closeBlock = "}"
module.delim.openFunctionParameterList = "("
module.delim.closeFunctionParameterList = ")"

--  separators --
module.sep.statement = ";"
module.delim.functionParameterSeparator = ","

return module
