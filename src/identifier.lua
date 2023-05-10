local lpeg = require "lpeg"
local tokens = require "tokens"
local translator = require "translator"
local endToken = require("common").endToken

local R, S = lpeg.R, lpeg.S
local Cmt = lpeg.Cmt

local geoalpha = S(translator.alphabet)
local alpha = R("AZ", "az") + geoalpha
local identifierStartCharacters = (alpha + "_")
local digit = R "09"
local identifierTailCharacters = (alpha + digit + "_")

local function getIdentifier(subject, position, match)
    if tokens.kw[match] then
        return false
    else
        return true, match
    end
end

return Cmt(identifierStartCharacters * (S "-" ^ -1 * identifierTailCharacters) ^ 0, getIdentifier) * endToken
