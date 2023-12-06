--[[
 Created by 0v3r5e3r
 Paste at the top of any script to add prefixes to the print() and warn() functions
--]]
local printPreix = "[INFO]"
local warnPrefix = "[WARN]"
local op = print; local ow = warn; local function print(a,...) op(printPrefix,a,...) end; local function warn(a,...) ow(warnPrefix,a,...) end