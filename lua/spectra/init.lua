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

  local theme_names = themes or colors.get_available_colorschemes()

  -- Use the batch extraction function
  cached_palettes, theme_list = colors.extract_all_palettes(theme_names)

  palettes_cached = true
end

---Setup spectra.nvim
---@param opts SpectraConfig?
function M.setup(opts)
  config.setup(opts)

  -- Restore persisted colorscheme immediately if available
  if config.options.persist then
    local saved = config.load_colorscheme()
    if saved then
      vim.schedule(function()
        pcall(vim.cmd, "colorscheme " .. saved)
      end)
    end
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
