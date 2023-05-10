local module = {}
local lu = require 'luaunit'
local identifier = require('common').testGrammar(require 'identifier')

function module:testIdentifiers()
    lu.assertEquals(identifier:match('_leading_underscore'), '_leading_underscore')
    lu.assertEquals(identifier:match('has spaces '), nil)
    lu.assertEquals(identifier:match('has-hyphens '), 'has-hyphens')
    lu.assertEquals(identifier:match('წერე_ქართულად'), 'წერე_ქართულად')
    lu.assertEquals(identifier:match('0not valid'), nil)
end

return module