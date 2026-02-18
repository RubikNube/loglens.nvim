### Commands

- `:LogLensOpen` — Analyze the current buffer and show matches in a separate window.
- `:LogLensClose` — Close the loglens window.
- `:LogLensConfigure` — Define or update log patterns on the fly, specifying regex and foreground/background colors.
- `:LogLensConfigureOpen` — Open the current pattern configuration in a separate window (JSON format) for editing. When you save and close the window, the new patterns are applied immediately.
- `:LogLensLoad` — Load a pattern configuration from a JSON file.
- `:LogLensSave` — Save the current pattern configuration to a JSON file.

#### Pattern Configuration Example

```lua
require("loglens").setup({
  patterns = {
    { regex = "ERROR",   fg = "#ffffff", bg = "#ff0000" },
    { regex = "WARN",    fg = "#000000", bg = "#ffff00" },
    { regex = "timeout", fg = "#ffffff", bg = "#ff8800" },
  }
})
```

#### On-the-fly Pattern Example

```
:LogLensConfigure /ERROR/ fg=#ffffff bg=#ff0000
```

#### Editing Patterns in JSON

Use `:LogLensConfigureOpen` to open and edit your patterns in JSON format, for example:

```json
[
  { "regex": "ERROR",   "fg": "#ffffff", "bg": "#ff0000" },
  { "regex": "WARN",    "fg": "#000000", "bg": "#ffff00" }
]
```
