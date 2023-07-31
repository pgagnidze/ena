package = 'Ena'
version = '0.0.2-2'
description = {
  summary = 'Ena: Georgian Programming Language',
  detailed = [[
    This language aims to make programming more accessible for Georgians by allowing them to write code in their native language. Ena uses the syntax of popular, widely-used languages, modified to use the Georgian alphabet and keywords.

    ეს ენა მიზნად ისახავს, ქართველებისთვის ხელმისაწვდომი გახადოს პროგრამირება, რაც გულისხმობს მშობლიურ ენაზე კოდის წერას. ენა იყენებს პოპულარული, ფართოდ გავრცელებული ენების სინტაქსს, რაც დაგვეხმარება მარტივად შევისწავლოთ პროგრამული ენის მახასიათებლები.
  ]],
  homepage = "http://github.com/pgagnidze/ena",
  maintainer = 'Papuna Gagnidze <pgagnidze@pm.me>',
  license = 'GPLv3'
}
source = {
	url = "git://github.com/pgagnidze/ena.git"
}
dependencies = {
  'lua >= 5.1',
  'lpeg ~> 1.0.2-1',
  'luaunit ~> 3.4-1'
}
build = {
  type = 'builtin',
  modules = {
    ["ena"] = "ena.lua",
    ["ena.parser"] = "ena/parser.lua",
    ["ena.compiler"] = "ena/compiler.lua",
    ["ena.interpreter"] = "ena/interpreter.lua",
    ["ena.transpiler"] = "ena/transpiler.lua",
    ["ena.lang.literals"] = "ena/lang/literals.lua",
    ["ena.lang.translator"] = "ena/lang/translator.lua",
    ["ena.helper.common"] = "ena/helper/common.lua",
    ["ena.helper.pegdebug"] = "ena/helper/pegdebug.lua",
    ["ena.helper.pt"] = "ena/helper/pt.lua",
    ["ena.spec.e2e"] = "ena/spec/e2e.lua",
  },
  install = {
    bin = {
      ena = 'ena.lua'
    },
  },
}