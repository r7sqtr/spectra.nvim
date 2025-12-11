-- Prevent loading twice
if vim.g.loaded_spectra then
  return
end
vim.g.loaded_spectra = true

-- Flag to track if we've successfully restored
vim.g.spectra_restored = false

-- IMPORTANT: If this plugin is lazy-loaded, the restoration logic below
-- won't run at startup. Users should either:
-- 1. Set lazy = false in their plugin config
-- 2. Add event = "VimEnter" or similar to ensure early loading
-- 3. Or use the recommended setup below in their init.lua/init.vim

-- Restore persisted colorscheme
-- Returns the saved colorscheme name if available, nil otherwise
local function get_saved_colorscheme()
  local path = vim.fn.stdpath("data") .. "/spectra.json"
  local ok, content = pcall(vim.fn.readfile, path)
  if ok and content and #content > 0 then
    local decode_ok, data = pcall(vim.fn.json_decode, table.concat(content, "\n"))
    if decode_ok and data and data.colorscheme then
      return data.colorscheme
    end
  end
  return nil
end

-- Map of theme names to lazy.nvim plugin names
local plugin_map = {
  tokyonight = "tokyonight.nvim",
  ["tokyonight-day"] = "tokyonight.nvim",
  ["tokyonight-moon"] = "tokyonight.nvim",
  ["tokyonight-night"] = "tokyonight.nvim",
  ["tokyonight-storm"] = "tokyonight.nvim",
  catppuccin = "catppuccin",
  ["catppuccin-frappe"] = "catppuccin",
  ["catppuccin-latte"] = "catppuccin",
  ["catppuccin-macchiato"] = "catppuccin",
  ["catppuccin-mocha"] = "catppuccin",
  kanagawa = "kanagawa.nvim",
  ["kanagawa-wave"] = "kanagawa.nvim",
  ["kanagawa-dragon"] = "kanagawa.nvim",
  ["kanagawa-lotus"] = "kanagawa.nvim",
  gruvbox = "gruvbox.nvim",
  everforest = "everforest-nvim",
  nord = "nord.nvim",
  nordic = "nordic.nvim",
  ["night-owl"] = "night-owl.nvim",
  ["solarized-osaka"] = "solarized-osaka.nvim",
  ayu = "neovim-ayu",
  ["ayu-dark"] = "neovim-ayu",
  ["ayu-light"] = "neovim-ayu",
  ["ayu-mirage"] = "neovim-ayu",
  palenight = "palenight.nvim",
  everblush = "nvim",
  ["monokai-pro"] = "monokai-pro.nvim",
  rose = "rose-pine",
  ["rose-pine"] = "rose-pine",
  ["rose-pine-main"] = "rose-pine",
  ["rose-pine-moon"] = "rose-pine",
  ["rose-pine-dawn"] = "rose-pine",
}

-- Try to load a colorscheme plugin via lazy.nvim
local function ensure_theme_loaded(theme)
  local ok, lazy = pcall(require, "lazy")
  if ok and lazy then
    local plugin_name = plugin_map[theme]
    if plugin_name then
      pcall(function()
        lazy.load({ plugins = { plugin_name } })
      end)
    end
  end
end

-- Check if a colorscheme is available
local function colorscheme_exists(name)
  local schemes = vim.fn.getcompletion("", "color")
  for _, scheme in ipairs(schemes) do
    if scheme == name then
      return true
    end
  end
  return false
end

-- Apply saved colorscheme
local function apply_saved_colorscheme()
  if vim.g.spectra_restored then
    return true
  end

  local saved = get_saved_colorscheme()
  if not saved then
    return false
  end

  -- Ensure lazy-loaded colorscheme plugin is loaded
  ensure_theme_loaded(saved)

  -- Check if the colorscheme is available
  if colorscheme_exists(saved) then
    -- Verify current colorscheme is different before applying
    if vim.g.colors_name == saved then
      vim.g.spectra_restored = true
      return true
    end

    local ok = pcall(vim.cmd, "colorscheme " .. saved)
    if ok then
      vim.g.spectra_restored = true
      return true
    end
  end

  return false
end

-- Try to restore immediately (works if colorscheme plugin is already loaded)
apply_saved_colorscheme()

-- Also try after VimEnter (when all plugins are loaded)
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("SpectraRestore", { clear = true }),
  callback = function()
    -- Delay to ensure all plugins are initialized (including lazy-loaded ones)
    vim.defer_fn(function()
      apply_saved_colorscheme()
    end, 50)
  end,
  once = true,
})

-- Also try after UIEnter (even later, after UI is fully ready)
vim.api.nvim_create_autocmd("UIEnter", {
  group = vim.api.nvim_create_augroup("SpectraRestoreUI", { clear = true }),
  callback = function()
    vim.defer_fn(function()
      apply_saved_colorscheme()
    end, 100)
  end,
  once = true,
})

-- Try after ColorScheme event (when any colorscheme loads, we can try to apply ours)
-- This handles the case where a default colorscheme is set before ours
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("SpectraRestoreColorScheme", { clear = true }),
  callback = function()
    -- Only try once, and only if we haven't restored yet
    if not vim.g.spectra_restored then
      vim.defer_fn(function()
        apply_saved_colorscheme()
      end, 10)
    end
  end,
})

-- Create user command
vim.api.nvim_create_user_command("Spectra", function()
  require("spectra").open()
end, { desc = "Open colorscheme picker" })

-- Create SpectraRefresh command
vim.api.nvim_create_user_command("SpectraRefresh", function()
  require("spectra").refresh()
  vim.notify("Spectra: Palette cache refreshed", vim.log.levels.INFO)
end, { desc = "Refresh colorscheme palette cache" })
