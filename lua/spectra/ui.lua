local api = vim.api
local config = require("spectra.config")
local colors_mod = require("spectra.colors")

local M = {}

-- NvChad-style icon for color swatches
local SWATCH_ICON = "󱓻 "

---@class SpectraState
---@field buf number|nil
---@field input_buf number|nil
---@field win number|nil
---@field input_win number|nil
---@field themes table<string, table>
---@field theme_list string[]
---@field filtered_themes string[]
---@field selected_index number
---@field original_scheme string|nil
---@field ns number
---@field hl_ns number
---@field longest_name number

---@type SpectraState
local state = {
  buf = nil,
  input_buf = nil,
  win = nil,
  input_win = nil,
  themes = {},
  theme_list = {},
  filtered_themes = {},
  selected_index = 1,
  original_scheme = nil,
  ns = 0,
  hl_ns = 0,
  longest_name = 0,
}

---Calculate the longest theme name
local function calc_longest_name()
  local longest = 0
  for _, name in ipairs(state.filtered_themes) do
    if #name > longest then
      longest = #name
    end
  end
  state.longest_name = longest
end

---Create all highlight groups for the picker in a dedicated namespace
---This uses a window-local namespace so colorscheme changes don't affect it
local function setup_highlights()
  -- Clear previous highlights in our namespace
  api.nvim_set_hl(state.hl_ns, "clear", {})

  for i, theme_name in ipairs(state.filtered_themes) do
    local palette = state.themes[theme_name]
    local swatch_colors = palette and colors_mod.get_swatch_colors(palette) or {}
    local is_selected = (i == state.selected_index)

    -- Get theme colors
    local theme_bg = palette and palette.bg or "#1a1a1a"
    local theme_fg = palette and palette.comment or "#888888"

    -- Check if light theme
    local is_light = palette and colors_mod.is_light_theme(palette)
    if is_light then
      theme_fg = "#333333"
    end

    -- For selected item, use a highlighted background and bright foreground
    local line_bg = theme_bg
    local name_fg = theme_fg
    if is_selected then
      -- Create a selection highlight overlay
      line_bg = is_light and "#d0d0d0" or "#3d4f6f"
      name_fg = is_light and "#000000" or "#ffffff"
    end

    -- Create line and name highlights in our namespace
    local line_hl = "SpectraLine" .. i
    local name_hl = "SpectraName" .. i
    api.nvim_set_hl(state.hl_ns, line_hl, { bg = line_bg, fg = theme_fg })
    api.nvim_set_hl(state.hl_ns, name_hl, { bg = line_bg, fg = name_fg, bold = is_selected })

    -- Create swatch highlights
    for j, color in ipairs(swatch_colors) do
      if j > 10 then
        break
      end
      local swatch_hl = "SpectraSwatch" .. i .. "_" .. j
      api.nvim_set_hl(state.hl_ns, swatch_hl, { fg = color, bg = line_bg })
    end

  end
end

---Render the theme list (NvChad compact style)
local function render_themes()
  if not state.buf or not api.nvim_buf_is_valid(state.buf) then
    return
  end

  api.nvim_buf_set_option(state.buf, "modifiable", true)
  api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)

  calc_longest_name()

  -- Setup all highlights first
  setup_highlights()

  local lines = {}

  for i, theme_name in ipairs(state.filtered_themes) do
    local palette = state.themes[theme_name]
    local swatch_colors = palette and colors_mod.get_swatch_colors(palette) or {}

    -- Build line content
    local padding = state.longest_name - #theme_name + 5
    local prefix = " "
    local line_content = prefix .. theme_name .. string.rep(" ", padding)

    -- Add swatch placeholders
    for j = 1, math.min(#swatch_colors, 10) do
      line_content = line_content .. SWATCH_ICON
    end

    table.insert(lines, line_content)
  end

  -- Set all lines at once
  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  -- Apply buffer highlights
  for i, theme_name in ipairs(state.filtered_themes) do
    local line = i - 1
    local palette = state.themes[theme_name]
    local swatch_colors = palette and colors_mod.get_swatch_colors(palette) or {}

    local line_hl = "SpectraLine" .. i
    local name_hl = "SpectraName" .. i

    -- Highlight entire line with theme background
    api.nvim_buf_add_highlight(state.buf, state.ns, line_hl, line, 0, -1)

    -- Highlight theme name
    api.nvim_buf_add_highlight(state.buf, state.ns, name_hl, line, 0, 1 + #theme_name)

    -- Highlight each swatch icon with its color
    local swatch_start = 1 + #theme_name + (state.longest_name - #theme_name + 5)
    local icon_width = #SWATCH_ICON

    for j = 1, math.min(#swatch_colors, 10) do
      local swatch_hl = "SpectraSwatch" .. i .. "_" .. j
      local col_start = swatch_start + (j - 1) * icon_width
      local col_end = col_start + icon_width
      api.nvim_buf_add_highlight(state.buf, state.ns, swatch_hl, line, col_start, col_end)
    end
  end

  api.nvim_buf_set_option(state.buf, "modifiable", false)

  -- Update window scroll position to keep selected item visible
  if state.win and api.nvim_win_is_valid(state.win) then
    local win_height = api.nvim_win_get_height(state.win)
    local cursor_line = state.selected_index

    local top_line = api.nvim_win_call(state.win, function()
      return vim.fn.line("w0")
    end)

    if cursor_line < top_line then
      api.nvim_win_set_cursor(state.win, { cursor_line, 0 })
    elseif cursor_line >= top_line + win_height then
      api.nvim_win_set_cursor(state.win, { cursor_line, 0 })
    end
  end
end

---Move selection up or down
---@param delta number
local function move_selection(delta)
  if #state.filtered_themes == 0 then
    return
  end

  local new_index = state.selected_index + delta

  if new_index < 1 then
    new_index = #state.filtered_themes
  elseif new_index > #state.filtered_themes then
    new_index = 1
  end

  state.selected_index = new_index

  -- Live preview - apply colorscheme FIRST
  if config.options.live_preview then
    local theme_name = state.filtered_themes[state.selected_index]
    if theme_name then
      pcall(vim.cmd, "silent! colorscheme " .. theme_name)
    end
  end

  -- Then re-render (which will recreate highlight groups)
  render_themes()
end

---Filter themes based on query
---@param query string|nil
local function filter_themes(query)
  if not query or query == "" then
    state.filtered_themes = vim.deepcopy(state.theme_list)
  else
    local result = {}
    for _, name in ipairs(state.theme_list) do
      if name:lower():find(query:lower(), 1, true) then
        table.insert(result, name)
      end
    end
    state.filtered_themes = result
  end

  if #state.filtered_themes > 0 then
    state.selected_index = math.min(state.selected_index, #state.filtered_themes)
    state.selected_index = math.max(1, state.selected_index)
  else
    state.selected_index = 0
  end

  render_themes()
end

---Apply the selected colorscheme
local function apply_selection()
  if #state.filtered_themes == 0 or state.selected_index == 0 then
    M.close(true)
    return
  end

  local theme_name = state.filtered_themes[state.selected_index]
  if theme_name then
    pcall(vim.cmd, "colorscheme " .. theme_name)
    if config.options.persist then
      config.save_colorscheme(theme_name)
    end
  end
  M.close(false)
end

---Close the picker
---@param restore boolean whether to restore original colorscheme
function M.close(restore)
  if restore and state.original_scheme then
    pcall(vim.cmd, "silent! colorscheme " .. state.original_scheme)
  end

  if state.input_win and api.nvim_win_is_valid(state.input_win) then
    api.nvim_win_close(state.input_win, true)
  end
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_close(state.win, true)
  end
  if state.input_buf and api.nvim_buf_is_valid(state.input_buf) then
    api.nvim_buf_delete(state.input_buf, { force = true })
  end
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    api.nvim_buf_delete(state.buf, { force = true })
  end

  state.win = nil
  state.input_win = nil
  state.buf = nil
  state.input_buf = nil

  vim.cmd("stopinsert")
end

---Setup keymaps
local function setup_keymaps()
  local opts = { noremap = true, nowait = true, silent = true }

  -- Input buffer keymaps
  local input_mappings = {
    ["<Down>"] = function() move_selection(1) end,
    ["<Up>"] = function() move_selection(-1) end,
    ["<C-j>"] = function() move_selection(1) end,
    ["<C-k>"] = function() move_selection(-1) end,
    ["<C-n>"] = function() move_selection(1) end,
    ["<C-p>"] = function() move_selection(-1) end,
    ["<CR>"] = apply_selection,
    ["<Esc>"] = function() M.close(true) end,
    ["<C-c>"] = function() M.close(true) end,
  }

  for key, fn in pairs(input_mappings) do
    vim.keymap.set("i", key, fn, vim.tbl_extend("force", opts, { buffer = state.input_buf }))
  end

  -- List buffer keymaps (normal mode)
  local list_mappings = {
    ["j"] = function() move_selection(1) end,
    ["k"] = function() move_selection(-1) end,
    ["<Down>"] = function() move_selection(1) end,
    ["<Up>"] = function() move_selection(-1) end,
    ["<CR>"] = apply_selection,
    ["q"] = function() M.close(true) end,
    ["<Esc>"] = function() M.close(true) end,
  }

  for key, fn in pairs(list_mappings) do
    vim.keymap.set("n", key, fn, vim.tbl_extend("force", opts, { buffer = state.buf }))
  end
end

---Open the colorscheme picker
---@param themes table<string, table> theme name -> palette mapping
---@param theme_list string[] ordered list of theme names
function M.open(themes, theme_list)
  -- Close existing picker if open
  if state.win and api.nvim_win_is_valid(state.win) then
    M.close(false)
  end

  -- Store state
  state.original_scheme = vim.g.colors_name
  state.themes = themes
  state.theme_list = vim.deepcopy(theme_list)
  state.filtered_themes = vim.deepcopy(theme_list)
  state.selected_index = 1
  state.ns = api.nvim_create_namespace("Spectra")
  state.hl_ns = api.nvim_create_namespace("SpectraHighlights")

  -- Find current theme in list
  for i, name in ipairs(state.filtered_themes) do
    if name == state.original_scheme then
      state.selected_index = i
      break
    end
  end

  local opts = config.options
  local height = math.min(opts.height, #state.filtered_themes)
  calc_longest_name()

  -- Calculate width based on content
  local icon_width = #SWATCH_ICON * 10 -- 10 swatch icons
  local width = state.longest_name + 5 + icon_width + 2 -- padding + margin
  width = math.max(width, opts.width)

  -- Create buffers
  state.buf = api.nvim_create_buf(false, true)
  state.input_buf = api.nvim_create_buf(false, true)

  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.input_buf].buftype = "prompt"
  vim.bo[state.input_buf].bufhidden = "wipe"

  -- Set prompt
  vim.fn.prompt_setprompt(state.input_buf, "   ")

  -- Calculate window positions (centered)
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines
  local row = math.floor((editor_height - height - 3) / 2)
  local col = math.floor((editor_width - width) / 2)

  -- Create input window
  state.input_win = api.nvim_open_win(state.input_buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = 1,
    style = "minimal",
    border = "rounded",
    title = "  Search ",
    title_pos = "center",
  })

  -- Create list window (below input)
  state.win = api.nvim_open_win(state.buf, false, {
    relative = "editor",
    row = row + 3,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " Colorschemes ",
    title_pos = "center",
  })

  -- Set window options
  vim.wo[state.input_win].cursorline = false
  vim.wo[state.input_win].number = false
  vim.wo[state.input_win].relativenumber = false
  vim.wo[state.input_win].signcolumn = "no"

  vim.wo[state.win].cursorline = false
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].scrolloff = 0

  -- Apply our highlight namespace to the list window
  -- This ensures colorscheme changes don't affect our highlights
  api.nvim_win_set_hl_ns(state.win, state.hl_ns)

  -- Setup keymaps
  setup_keymaps()

  -- Handle text input for filtering
  api.nvim_create_autocmd("TextChangedI", {
    buffer = state.input_buf,
    callback = function()
      local lines = api.nvim_buf_get_lines(state.input_buf, 0, 1, false)
      local text = lines[1] or ""
      -- Remove prompt prefix
      local query = text:gsub("^%s*", "")
      vim.schedule(function()
        filter_themes(query)
      end)
    end,
  })

  -- Auto-close on focus loss
  api.nvim_create_autocmd("WinLeave", {
    buffer = state.input_buf,
    callback = function()
      vim.schedule(function()
        if state.win then
          M.close(true)
        end
      end)
    end,
  })

  -- Initial render
  render_themes()

  -- Focus input and start insert mode
  api.nvim_set_current_win(state.input_win)
  vim.cmd("startinsert!")
end

return M
