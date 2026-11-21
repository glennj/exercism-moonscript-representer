#!/usr/bin/env moon

require 'moonscript'

VERSION = 1.1

parser = require 'lua-parser.parser'
pp = require 'lua-parser.pp'

file = require 'pl.file'
dir = require 'pl.dir'
utils = require 'pl.utils'
json = require 'dkjson'

-- TODO validate args
slug, in_dir, out_dir = table.unpack arg

repr_file = "#{out_dir}/representer.txt"
map_file = "#{out_dir}/mapping.json"

file.write "#{out_dir}/representer.json", json.encode({version: VERSION})

src_files = dir.getfiles in_dir, "*.moon"
reprs = {}

id_num = 0
mapping = {}

for file in *src_files
  continue if file\match "_spec.moon$"

  lua_file = file\gsub "%.moon$", ".lua"
  utils.execute "moonc #{file}"
  src = utils.readfile lua_file
  ast = pp.tostring parser.parse(src, file)
  normalized = ast\gsub "(Id \")([^\"]+)", (s, t) ->
    ident = mapping[t]
    if not ident
      id_num += 1
      ident = "IDENT_#{id_num}"
      mapping[t] = ident
    "#{s}#{ident}"

  table.insert reprs, normalized

file.write repr_file, table.concat(reprs, "\n\n")

map_str = json.encode {v, k for k, v in pairs mapping}, {indent: true}
file.write map_file, map_str

