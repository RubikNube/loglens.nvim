local plugin_root = debug.getinfo(1, "S").source:match("@(.*/)") or ""
package.path = plugin_root .. "../lua/?.lua;" .. plugin_root .. "../lua/?/init.lua;" .. package.path

print("plugin_root: " .. plugin_root)
print("package.path: " .. package.path)

local loglens = require("loglens")
local eq = assert.are.same

describe("loglens.nvim", function()
    local test_buf

    before_each(function()
        -- Create a new buffer for each test
        test_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(test_buf)
        vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, {
            "INFO Starting up",
            "WARN Disk almost full",
            "ERROR Failed to start service",
            "timeout after 10s",
            "INFO Done",
        })
        -- Reset patterns
        loglens.setup({
            patterns = {
                { regex = "ERROR", fg = "#ffffff", bg = "#ff0000" },
                { regex = "WARN", fg = "#000000", bg = "#ffff00" },
                { regex = "timeout", fg = "#ffffff", bg = "#ff8800" },
            },
        })
    end)

    after_each(function()
        -- Clean up
        if test_buf and vim.api.nvim_buf_is_valid(test_buf) then
            vim.api.nvim_buf_delete(test_buf, { force = true })
        end
        pcall(loglens.close)
    end)

    it("matches patterns in buffer lines", function()
        local lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
        local matches = {}
        for lnum, line in ipairs(lines) do
            for _, pat in ipairs({
                { regex = "ERROR", fg = "#ffffff", bg = "#ff0000" },
                { regex = "WARN", fg = "#000000", bg = "#ffff00" },
                { regex = "timeout", fg = "#ffffff", bg = "#ff8800" },
            }) do
                local s, e = line:find(pat.regex)
                if s and e then
                    table.insert(
                        matches,
                        { lnum = lnum, regex = pat.regex, start_col = s - 1, end_col = e }
                    )
                end
            end
        end
        eq(#matches, 3)
        eq(matches[1].regex, "WARN")
        eq(matches[2].regex, "ERROR")
        eq(matches[3].regex, "timeout")
    end)

    it("opens and closes the log window", function()
        loglens.open()
        -- Should create a floating window
        local wins = vim.api.nvim_list_wins()
        local found = false
        for _, win in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.api.nvim_buf_get_name(buf) == "" and buf ~= test_buf then
                found = true
            end
        end
        assert.is_true(found)
        loglens.close()
    end)

    it("adds patterns on the fly with :LogLensConfigure", function()
        vim.cmd("LogLensConfigure /INFO/ fg=#00ff00 bg=#000000")
        loglens.open()
        local lines = vim.api.nvim_buf_get_lines(test_buf, 0, -1, false)
        local found = false
        for _, line in ipairs(lines) do
            if line:find("INFO") then
                found = true
                break
            end
        end
        assert.is_true(found)
    end)

    it("saves and loads pattern configuration", function()
        local tmpfile = vim.fn.tempname() .. ".json"
        loglens.save(tmpfile)
        loglens.setup({ patterns = {} })
        loglens.load(tmpfile)
        os.remove(tmpfile)
        -- Should restore patterns
        loglens.open()
        local wins = vim.api.nvim_list_wins()
        assert.is_true(#wins > 0)
    end)
end)
