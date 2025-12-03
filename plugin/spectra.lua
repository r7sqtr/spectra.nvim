-- Prevent loading twice
if vim.g.loaded_spectra then
  return
end
vim.g.loaded_spectra = true

-- Create user command
vim.api.nvim_create_user_command("Spectra", function()
  require("spectra").open()
end, { desc = "Open colorscheme picker" })

-- Create SpectraRefresh command
vim.api.nvim_create_user_command("SpectraRefresh", function()
  require("spectra").refresh()
  vim.notify("Spectra: Palette cache refreshed", vim.log.levels.INFO)
end, { desc = "Refresh colorscheme palette cache" })
