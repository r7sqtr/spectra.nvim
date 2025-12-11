# spectra.nvim

[日本語](README.ja.md)

NvChad-style colorscheme picker for Neovim with color palette preview.

![Neovim](https://img.shields.io/badge/Neovim-0.9+-green.svg)

<img width="2632" height="1729" alt="features" src="https://github.com/user-attachments/assets/4896cf79-4e47-46e3-a0d6-eb44fec41ed2" />

## Features

- Floating popup UI with search/filter
- Color palette swatches next to each theme
- Real-time preview while navigating
- Persistence across sessions
- Light theme indicator

## Requirements

- Neovim >= 0.9.0
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)

## Installation

### lazy.nvim

```lua
{
  "r7sqtr/spectra.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  lazy = true,
  cmd = "Spectra",
  keys = {
    { "<leader>sp", "<cmd>Spectra<cr>", desc = "Open Spectra" },
  },
  opts = {
    -- your configuration here
  },
}
```

## Configuration

```lua
require("spectra").setup({
  -- List of colorschemes to show (nil = auto-detect)
  themes = nil,

  -- Popup dimensions
  width = 50,
  height = 15,

  -- Border style ("rounded", "single", "double", etc.)
  border = "rounded",

  -- Enable live preview when navigating
  live_preview = true,

  -- Persist selected colorscheme across sessions
  persist = true,
})
```

## Keybindings

| Key | Action |
|-----|--------|
| `j` / `<Down>` / `<C-j>` / `<C-n>` | Next theme |
| `k` / `<Up>` / `<C-k>` / `<C-p>` | Previous theme |
| `<CR>` | Apply selected theme |
| `<Esc>` / `q` / `<C-c>` | Cancel (restore original) |
| Type characters | Filter themes |

## Commands

- `:Spectra` - Open the colorscheme picker
- `:SpectraRefresh` - Refresh the color palette cache

## License

MIT
