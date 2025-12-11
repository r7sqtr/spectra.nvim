---@class SpectraConfig
---@field themes string[]|nil List of colorscheme names (nil = auto-detect)
---@field width number Popup width
---@field height number Popup height
---@field border string Border style
---@field live_preview boolean Enable live preview on navigation
---@field persist boolean Persist selection across sessions

local M = {}

M.defaults = {
  themes = nil, -- nil means auto-detect available colorschemes
  width = 50,
  height = 15,
  border = "rounded",
  live_preview = true,
  persist = true,
}

---@type SpectraConfig
M.options = {}

---Setup configuration
---@param opts SpectraConfig?
function M.setup(opts)
  opts = opts or {}
  -- Explicitly handle nil themes to ensure it stays nil (auto-detect)
  local themes = opts.themes
  opts.themes = nil
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts)
  -- Restore themes after merge (nil means auto-detect, so only set if explicitly provided)
  if themes ~= nil then
    M.options.themes = themes
  end
end

---Get the data file path for persistence
---@return string
function M.get_data_path()
  return vim.fn.stdpath("data") .. "/spectra.json"
end

---Check if a colorscheme is available
---@param name string
---@return boolean
function M.colorscheme_exists(name)
  if not name or name == "" then
    return false
  end
  local schemes = vim.fn.getcompletion("", "color")
  for _, scheme in ipairs(schemes) do
    if scheme == name then
      return true
    end
  end
  return false
end

---Load persisted colorscheme
---@return string|nil
function M.load_colorscheme()
  local path = M.get_data_path()
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok or not content or #content == 0 then
    return nil
  end

  local decode_ok, data = pcall(vim.fn.json_decode, table.concat(content, "\n"))
  if not decode_ok or not data or not data.colorscheme then
    return nil
  end

  return data.colorscheme
end

---Save colorscheme to persistence file
---@param colorscheme string
function M.save_colorscheme(colorscheme)
  if not colorscheme or colorscheme == "" then
    return
  end

  local path = M.get_data_path()
  local encode_ok, data = pcall(vim.fn.json_encode, { colorscheme = colorscheme })
  if not encode_ok then
    vim.notify("Spectra: Failed to encode colorscheme data", vim.log.levels.WARN)
    return
  end

  local write_ok = pcall(vim.fn.writefile, { data }, path)
  if not write_ok then
    vim.notify("Spectra: Failed to save colorscheme", vim.log.levels.WARN)
  end
end

---Apply saved colorscheme if available
---@return boolean success
function M.apply_saved_colorscheme()
  if vim.g.spectra_restored then
    return true
  end

  local saved = M.load_colorscheme()
  if not saved then
    return false
  end

  -- Ensure lazy-loaded colorscheme plugin is loaded
  local colors_ok, colors = pcall(require, "spectra.colors")
  if colors_ok and colors.ensure_theme_loaded then
    colors.ensure_theme_loaded(saved)
  end

  if not M.colorscheme_exists(saved) then
    return false
  end

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

  return false
end

return M
