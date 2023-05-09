local lpeg = require "lpeg"
local literals = require "literals"

local P = lpeg.P
local V = lpeg.V

local common = {}

common.endToken = V "endToken"

function common.I(tag)
    return P(
        function()
            print(tag)
            return true
        end
    )
end

local lineComment = literals.comments.startLine * (P(1) - "\n") ^ 0
local blockComment =
    literals.comments.openBlock * (P(1) - P(literals.comments.closeBlock)) ^ 0 * literals.comments.closeBlock
local furthestMatch = 0
common.endTokenPattern =
    (lpeg.locale().space + blockComment + lineComment) ^ 0 *
    P(
        function(_, position)
            furthestMatch = math.max(furthestMatch, position)
            return true
        end
    )

function common.testGrammar(pattern)
    return P {pattern * -1, endToken = common.endTokenPattern}
end

function common.getFurthestMatch()
    return furthestMatch
end

function common.clearFurthestMatch()
    furthestMatch = 0
end

-- Counts the number of occurrences of substring in string
function common.count(substring, string)
    local matches = 0
    ((P(substring) / function()
            matches = matches + 1
        end + 1) ^ 0):match(string)
    return matches
end

return common
