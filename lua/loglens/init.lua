local M = {}

local patterns = {}
local config_win = nil
local config_buf = nil
local log_win = nil
local log_buf = nil

local function apply_highlights(buf, matches)
	vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
	for _, match in ipairs(matches) do
		local ns = vim.api.nvim_create_namespace("loglens_" .. match.regex)
		-- Highlight the entire line
		vim.api.nvim_buf_add_highlight(buf, ns, match.hl_group, match.lnum - 1, 0, -1)
	end
end

local function make_hl_group(fg, bg)
	local group = "LogLensHL_" .. fg:gsub("#", "") .. "_" .. bg:gsub("#", "")
	if vim.fn.hlID(group) == 0 then
		vim.api.nvim_set_hl(0, group, { fg = fg, bg = bg })
	end
	return group
end

local function match_lines(lines)
	local matches = {}
	for lnum, line in ipairs(lines) do
		for _, pat in ipairs(patterns) do
			local s, e = line:find(pat.regex)
			if s and e then
				local hl_group = make_hl_group(pat.fg, pat.bg)
				table.insert(matches, {
					lnum = lnum,
					regex = pat.regex,
					hl_group = hl_group,
					line = line,
					start_col = 0,
					end_col = -1,
				})
				-- No break: allow multiple highlights per line
			end
		end
	end
	return matches
end

local function open_log_window(matches)
	if log_win and vim.api.nvim_win_is_valid(log_win) then
		vim.api.nvim_win_close(log_win, true)
	end
	log_buf = vim.api.nvim_create_buf(false, true)
	local lines = {}
	for _, m in ipairs(matches) do
		table.insert(lines, m.line)
	end
	-- Show every match as a separate line, even if content is identical
	vim.api.nvim_buf_set_lines(log_buf, 0, -1, false, lines)
	log_win = vim.api.nvim_open_win(log_buf, true, {
		relative = "editor",
		width = math.floor(vim.o.columns * 0.8),
		height = math.floor(vim.o.lines * 0.4),
		row = math.floor(vim.o.lines * 0.3),
		col = math.floor(vim.o.columns * 0.1),
		style = "minimal",
		border = "rounded",
	})
	-- Set focus to the filtered window
	vim.api.nvim_set_current_win(log_win)
	-- Apply highlights: each line is a match, so lnum = index in lines
	for i, match in ipairs(matches) do
		local ns = vim.api.nvim_create_namespace("loglens_" .. match.regex)
		vim.api.nvim_buf_add_highlight(log_buf, ns, match.hl_group, i - 1, 0, -1)
	end
end

function M.setup(opts)
	patterns = opts.patterns or {}
end

function M.open()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	-- Split lines containing multiple log entries
	local split_lines = {}
	for _, line in ipairs(lines) do
		-- Split by date pattern (assumes ISO format at start of each entry)
		local i = 1
		for entry in line:gmatch("(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d [^\n]+)") do
			table.insert(split_lines, entry)
			i = i + 1
		end
		if i == 1 then
			table.insert(split_lines, line)
		end
	end
	-- Debug: print split_lines and matches
	print("split_lines:")
	for _, l in ipairs(split_lines) do
		print(l)
	end
	local matches = match_lines(split_lines)
	print("matches:")
	for _, m in ipairs(matches) do
		print(vim.inspect(m))
	end
	open_log_window(matches)
end

function M.close()
	if log_win and vim.api.nvim_win_is_valid(log_win) then
		vim.api.nvim_win_close(log_win, true)
		log_win = nil
		log_buf = nil
	end
end

function M.configure(args)
	-- Example: /ERROR/ fg=#ffffff bg=#ff0000
	local regex = args:match("/(.-)/")
	local fg = args:match("fg=#[%da-fA-F]+")
	local bg = args:match("bg=#[%da-fA-F]+")
	fg = fg and fg:sub(4)
	bg = bg and bg:sub(4)
	if regex and fg and bg then
		table.insert(patterns, { regex = regex, fg = fg, bg = bg })
		print("Pattern added: " .. regex)
	else
		print("Usage: :LogLensConfigure /REGEX/ fg=#RRGGBB bg=#RRGGBB")
	end
end

local function patterns_to_json()
	local json = vim.fn.json_encode(patterns)
	return vim.split(json, "\n")
end

local function json_to_patterns(json_lines)
	local ok, parsed = pcall(vim.fn.json_decode, table.concat(json_lines, "\n"))
	if ok and type(parsed) == "table" then
		patterns = parsed
		return true
	end
	return false
end

function M.configure_open()
	if config_win and vim.api.nvim_win_is_valid(config_win) then
		vim.api.nvim_win_close(config_win, true)
	end
	config_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(config_buf, 0, -1, false, patterns_to_json())
	config_win = vim.api.nvim_open_win(config_buf, true, {
		relative = "editor",
		width = math.floor(vim.o.columns * 0.6),
		height = math.floor(vim.o.lines * 0.5),
		row = math.floor(vim.o.lines * 0.25),
		col = math.floor(vim.o.columns * 0.2),
		style = "minimal",
		border = "rounded",
	})
	vim.api.nvim_buf_set_option(config_buf, "filetype", "json")
	vim.api.nvim_create_autocmd("BufWritePost", {
		buffer = config_buf,
		once = true,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(config_buf, 0, -1, false)
			if json_to_patterns(lines) then
				print("Patterns updated.")
			else
				print("Invalid JSON.")
			end
		end,
	})
end

function M.load(file)
	local lines = vim.fn.readfile(file)
	if json_to_patterns(lines) then
		print("Patterns loaded from " .. file)
	else
		print("Failed to load patterns from " .. file)
	end
end

function M.save(file)
	vim.fn.writefile(patterns_to_json(), file)
	print("Patterns saved to " .. file)
end

vim.api.nvim_create_user_command("LogLensOpen", function()
	M.open()
end, {})
vim.api.nvim_create_user_command("LogLensClose", function()
	M.close()
end, {})
vim.api.nvim_create_user_command("LogLensConfigure", function(opts)
	M.configure(opts.args)
end, { nargs = "*" })
vim.api.nvim_create_user_command("LogLensConfigureOpen", function()
	M.configure_open()
end, {})
vim.api.nvim_create_user_command("LogLensLoad", function(opts)
	M.load(opts.args)
end, { nargs = 1 })
vim.api.nvim_create_user_command("LogLensSave", function(opts)
	M.save(opts.args)
end, { nargs = 1 })

return M
