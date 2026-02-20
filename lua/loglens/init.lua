local M = {}

local state = {}
local patterns = {}
local line_map = {}
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
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_set_current_win(state.win)
		return
	end

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "filetype", "loglens")

	local cur_win = vim.api.nvim_get_current_win()
	vim.cmd("vsplit")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	vim.api.nvim_set_current_win(cur_win)

	state.win = win
	state.buf = buf

	M._render(buf)
end

function M.close()
	if log_win and vim.api.nvim_win_is_valid(log_win) then
		vim.api.nvim_win_close(log_win, true)
		log_win = nil
		log_buf = nil
	end
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
		state.win = nil
		state.buf = nil
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
	-- Pretty-print JSON: 2-space indent, each pattern on its own line
	local json = vim.fn.json_encode(patterns)
	-- Insert newlines and indentation for readability
	json = json:gsub("%[%s*{", "[\n  {"):gsub("},%s*{", "},\n  {"):gsub("}%s*%]", "}\n]")
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
	vim.api.nvim_create_autocmd({ "BufWritePost", "BufWinLeave" }, {
		buffer = config_buf,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(config_buf, 0, -1, false)
			if json_to_patterns(lines) then
				print("Patterns updated.")
				-- Refresh loglens view if open
				if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
					M._render(state.buf)
				end
			else
				print("Invalid JSON.")
			end
		end,
	})
end

function M.configure_close()
	if config_win and vim.api.nvim_win_is_valid(config_win) then
		vim.api.nvim_win_close(config_win, true)
		config_win = nil
		config_buf = nil
	end
end

vim.api.nvim_create_user_command("LogLensConfigureClose", function()
	M.configure_close()
end, {})

function M.save(file)
	file = vim.fn.expand(file)
	vim.fn.writefile(patterns_to_json(), file)
	print("Patterns saved to " .. file)
end

function M.load(file)
	file = vim.fn.expand(file)
	local lines = vim.fn.readfile(file)
	if json_to_patterns(lines) then
		print("Patterns loaded from " .. file)
	else
		print("Failed to load patterns from " .. file)
	end
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

function M._render(buf)
	-- Get lines from the original buffer (the one to analyze)
	local src_buf = nil
	if state and state.buf == buf and state.src_buf then
		src_buf = state.src_buf
	else
		-- Use the window to the left (assume vsplit)
		local cur_win = vim.api.nvim_get_current_win()
		local wins = vim.api.nvim_tabpage_list_wins(0)
		local idx = nil
		for i, win in ipairs(wins) do
			if win == cur_win then
				idx = i
			end
		end
		if idx and idx > 1 then
			src_buf = vim.api.nvim_win_get_buf(wins[idx - 1])
		else
			src_buf = vim.api.nvim_get_current_buf()
		end
		state.src_buf = src_buf
	end

	local lines = vim.api.nvim_buf_get_lines(src_buf, 0, -1, false)
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
			end
		end
	end

	-- Set lines in the loglens buffer and build line_map
	local out_lines = {}
	line_map = {}
	for i, m in ipairs(matches) do
		table.insert(out_lines, m.line)
		line_map[i] = m.lnum
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, out_lines)

	-- Highlight matches
	for i, match in ipairs(matches) do
		local ns = vim.api.nvim_create_namespace("loglens_" .. match.regex)
		vim.api.nvim_buf_add_highlight(buf, ns, match.hl_group, i - 1, 0, -1)
	end

	-- Map <CR> to jump to the original buffer and line using a global function
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"<CR>",
		string.format([[:lua loglens_goto_line(%d)<CR>]], src_buf),
		{ noremap = true, silent = true }
	)
end

_G.loglens_goto_line = function(src_buf)
	local cur_line = vim.api.nvim_win_get_cursor(0)[1]
	local target_line = line_map[cur_line]
	if not target_line then
		return
	end

	-- Find a window showing src_buf, or open one in a split if not found
	local found_win = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == src_buf then
			found_win = win
			break
		end
	end
	if not found_win then
		-- Open the buffer in a new vertical split
		vim.cmd("vsplit")
		found_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(found_win, src_buf)
	end
	-- Move cursor in the found window
	vim.api.nvim_win_set_cursor(found_win, { target_line, 0 })
	-- Return focus to the loglens window
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == vim.api.nvim_get_current_buf() then
			vim.api.nvim_set_current_win(win)
			break
		end
	end
end

return M
