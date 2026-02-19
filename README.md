# LogLens.nvim

A Neovim plugin for interactive log file analysis. Highlight, filter, and jump between log entries using customizable patterns and a split window interface.

---

## Features

- Highlight log lines matching user-defined patterns (regex, color).
- Quickly filter and view matching lines in a vertical split.
- Jump to the original log line from the filtered view without leaving the split.
- Edit and manage pattern configurations on the fly (command or JSON).
- Save/load pattern configurations as JSON.

---

## Installation

**With [lazy.nvim](https://github.com/folke/lazy.nvim):**
```lua
{
  "yourusername/loglens.nvim",
  config = function()
    require("loglens").setup()
  end
}
```

**With [packer.nvim](https://github.com/wbthomason/packer.nvim):**
```lua
use {
  "yourusername/loglens.nvim",
  config = function()
    require("loglens").setup()
  end
}
```

---

## Usage

Open a log file, then run:
```
:LogLensOpen
```
This opens a vertical split with all lines matching your patterns.  
Press `<CR>` (Enter) on a line in the loglens split to jump to the corresponding line in the original buffer (the original buffer will be focused in another split, but your cursor remains in the loglens view).

---

## Commands

| Command                   | Description                                                                                                   |
|---------------------------|---------------------------------------------------------------------------------------------------------------|
| `:LogLensOpen`            | Analyze the current buffer and show matches in a vertical split. Press `<CR>` to jump to the original buffer. |
| `:LogLensClose`           | Close the loglens window.                                                                                     |
| `:LogLensConfigure`       | Define or update log patterns on the fly. Usage: `:LogLensConfigure /REGEX/ fg=#RRGGBB bg=#RRGGBB`            |
| `:LogLensConfigureOpen`   | Open the current pattern configuration in a separate window (JSON format) for editing.                        |
| `:LogLensConfigureClose`  | Close the pattern configuration window if open.                                                               |
| `:LogLensLoad {file}`     | Load a pattern configuration from a JSON file.                                                                |
| `:LogLensSave {file}`     | Save the current pattern configuration to a JSON file.                                                        |

---

## Pattern Configuration Example

```lua
require("loglens").setup({
  patterns = {
    { regex = "ERROR",   fg = "#ffffff", bg = "#ff0000" },
    { regex = "WARN",    fg = "#000000", bg = "#ffff00" },
    { regex = "timeout", fg = "#ffffff", bg = "#ff8800" },
  }
})
```

---

## On-the-fly Pattern Example

```
:LogLensConfigure /ERROR/ fg=#ffffff bg=#ff0000
```

---

## Editing Patterns in JSON

Use `:LogLensConfigureOpen` to open and edit your patterns in JSON format, for example:
```json
[
  { "regex": "ERROR",   "fg": "#ffffff", "bg": "#ff0000" },
  { "regex": "WARN",    "fg": "#000000", "bg": "#ffff00" }
]
```

---

## Example

![LogLens Demo](./media/loglens-demo.gif)

---

## Troubleshooting

- **No matches found:** Check your pattern regex and color format.
- **Jumping doesn't work:** Ensure you are pressing `<CR>` in the loglens split, and that your Neovim version supports Lua plugins.

---

## Contributing

Pull requests and issues are welcome! Please open an issue for bugs or feature requests.

---

## License

MIT
