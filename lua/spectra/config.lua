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

---Load persisted colorscheme
---@return string|nil
function M.load_colorscheme()
  local path = M.get_data_path()
  local ok, content = pcall(vim.fn.readfile, path)
  if ok and content and #content > 0 then
    local data = vim.fn.json_decode(table.concat(content, "\n"))
    if data and data.colorscheme then
      return data.colorscheme
    end
  end
  return nil
end

---Save colorscheme to persistence file
---@param colorscheme string
function M.save_colorscheme(colorscheme)
  local path = M.get_data_path()
  local data = vim.fn.json_encode({ colorscheme = colorscheme })
  vim.fn.writefile({ data }, path)
end

return M
