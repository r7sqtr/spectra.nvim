local M = {}

local config = require("spectra.config")
local colors = require("spectra.colors")
local ui = require("spectra.ui")

---@type table<string, table> Cached color palettes
local cached_palettes = {}

---@type string[] Ordered list of theme names
local theme_list = {}

---@type boolean Whether palettes have been cached
local palettes_cached = false

---Cache color palettes for all themes
---@param themes string[]|nil
local function cache_palettes(themes)
  if palettes_cached then
    return
  end

  -- Handle nil or empty themes - use auto-detection
  local theme_names
  if themes and type(themes) == "table" and #themes > 0 then
    theme_names = themes
  else
    theme_names = colors.get_available_colorschemes()
  end

  -- Use the batch extraction function
  cached_palettes, theme_list = colors.extract_all_palettes(theme_names)

  palettes_cached = true
end

---Setup spectra.nvim
---@param opts SpectraConfig?
function M.setup(opts)
  config.setup(opts)

  -- Restore persisted colorscheme if enabled
  if config.options.persist then
    -- Try to restore immediately
    config.apply_saved_colorscheme()

    -- Also set up VimEnter autocmd to ensure restoration after all plugins load
    -- This is especially important when lazy loading colorscheme plugins
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("SpectraSetupRestore", { clear = true }),
      callback = function()
        vim.defer_fn(function()
          config.apply_saved_colorscheme()
        end, 50)
      end,
      once = true,
    })

    -- Also try after UIEnter for maximum compatibility
    vim.api.nvim_create_autocmd("UIEnter", {
      group = vim.api.nvim_create_augroup("SpectraSetupRestoreUI", { clear = true }),
      callback = function()
        vim.defer_fn(function()
          config.apply_saved_colorscheme()
        end, 100)
      end,
      once = true,
    })
  end
end

---Open the colorscheme picker
function M.open()
  -- Cache palettes on first open (not during startup to avoid flicker)
  if not palettes_cached then
    cache_palettes(config.options.themes)
  end

  ui.open(cached_palettes, theme_list)
end

---Close the picker
---@param restore boolean|nil
function M.close(restore)
  ui.close(restore or false)
end

---Get available themes
---@return string[]
function M.get_themes()
  return vim.deepcopy(theme_list)
end

---Refresh palette cache
function M.refresh()
  cached_palettes = {}
  theme_list = {}
  palettes_cached = false
  cache_palettes(config.options.themes)
  vim.notify("Spectra: Palette cache refreshed (" .. #theme_list .. " themes)", vim.log.levels.INFO)
end

return M
