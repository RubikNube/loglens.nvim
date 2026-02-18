local plugin_root = debug.getinfo(1, "S").source:match("@(.*/)") or ""
package.path = plugin_root .. "../lua/?.lua;" .. plugin_root .. "../lua/?/init.lua;" .. package.path
print("plugin_root: " .. plugin_root)
print("package.path: " .. package.path)
local ok, mod = pcall(require, "loglens")
print("require('loglens') ok:", ok)
if not ok then
	print(mod)
end
