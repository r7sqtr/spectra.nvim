-- Prevent loading twice
if vim.g.loaded_spectra then
  return
end
vim.g.loaded_spectra = true

-- Restore persisted colorscheme early (before setup is called)
-- This ensures the colorscheme is applied even when lazy-loaded
local function restore_colorscheme()
  local path = vim.fn.stdpath("data") .. "/spectra.json"
  local ok, content = pcall(vim.fn.readfile, path)
  if ok and content and #content > 0 then
    local decode_ok, data = pcall(vim.fn.json_decode, table.concat(content, "\n"))
    if decode_ok and data and data.colorscheme then
      vim.schedule(function()
        pcall(vim.cmd, "colorscheme " .. data.colorscheme)
      end)
    end
  end
end

-- Restore colorscheme on startup
restore_colorscheme()

-- Create user command
vim.api.nvim_create_user_command("Spectra", function()
  require("spectra").open()
end, { desc = "Open colorscheme picker" })

-- Create SpectraRefresh command
vim.api.nvim_create_user_command("SpectraRefresh", function()
  require("spectra").refresh()
  vim.notify("Spectra: Palette cache refreshed", vim.log.levels.INFO)
end, { desc = "Refresh colorscheme palette cache" })
