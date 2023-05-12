package = 'Ena'
version = '0.0.1-1'
description = {
  summary = 'Ena: The First Georgian Programming Language',
  detailed = [[
    Ena, the first programming language developed for the Georgian community.
    This language aims to make programming more accessible for Georgians by allowing them to write code in their native language.
    Ena uses the syntax of popular, widely-used languages, modified to use the Georgian alphabet and keywords.

    ენა, პირველი ქართული პროგრამული ენა.
    ეს ენა მიზნად ისახავს ქართველებისთვის უფრო ხელმისაწვდომი გახადოს პროგრამირება, რაც გულისხმობს მშობლიურ ენაზე კოდის წერას.
    ენა იყენებს პოპულარული, ფართოდ გავრცელებული ენების სინტაქსს, რომელიც დაგვეხმარება მარტივად შევისწავლოთ პროგრამული ენის მახასიათებლები.
  ]],
  homepage = "http://github.com/pgagnidze/ena",
  maintainer = 'Papuna Gagnidze <pgagnidze@pm.me>',
  license = 'GPLv3'
}
source = {
	url = "git://github.com/pgagnidze/ena.git"
}
dependencies = {
  'lua ~> 5.4',
  'lpeg ~> 1.0.2-1',
  'luaunit ~> 3.4-1'
}
build = {
  type = 'builtin',
  modules = {
    ["ena"] = "src/ena.lua",
  },
  copy_directories = { "src" }
}