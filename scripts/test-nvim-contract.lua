-- Shim: test/nvim/contract.lua
local src = debug.getinfo(1, "S").source:sub(2)
local root = src:match("(.+)/scripts/")
dofile(root .. "/test/nvim/contract.lua")
