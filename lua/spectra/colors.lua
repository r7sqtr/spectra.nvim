local M = {}

-- Highlight groups to extract colors from (in priority order)
M.highlight_groups = {
  -- Background
  { "Normal", "bg" },
  -- Grays/Comments
  { "Comment", "fg" },
  { "NonText", "fg" },
  -- Greens (strings)
  { "String", "fg" },
  { "@string", "fg" },
  -- Blues (functions)
  { "Function", "fg" },
  { "@function", "fg" },
  -- Purples/Magentas (keywords)
  { "Keyword", "fg" },
  { "Statement", "fg" },
  { "@keyword", "fg" },
  -- Yellows/Oranges (types)
  { "Type", "fg" },
  { "@type", "fg" },
  -- Numbers
  { "Number", "fg" },
  { "Constant", "fg" },
  { "@number", "fg" },
  -- Warnings
  { "DiagnosticWarn", "fg" },
  { "WarningMsg", "fg" },
  -- Info/Cyan
  { "DiagnosticInfo", "fg" },
  { "Special", "fg" },
  -- Errors/Red
  { "Error", "fg" },
  { "DiagnosticError", "fg" },
  { "ErrorMsg", "fg" },
}

---Convert RGB integer to hex string
---@param rgb number
---@return string
local function rgb_to_hex(rgb)
  return string.format("#%06x", rgb)
end

---Extract colors from current colorscheme
---@return table<string, string>
local function extract_current_colors()
  local colors = {}
  local color_map = {}

  for _, group_info in ipairs(M.highlight_groups) do
    local group_name = group_info[1]
    local attr = group_info[2]

    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group_name, link = false })
    if ok and hl then
      local color_val = attr == "bg" and hl.bg or hl.fg

      if color_val and type(color_val) == "number" then
        local hex = rgb_to_hex(color_val)

        -- Determine category
        local category = nil
        if group_name == "Normal" and attr == "bg" then
          category = "bg"
        elseif group_name:match("[Cc]omment") or group_name:match("NonText") then
          category = "comment"
        elseif group_name:match("[Ss]tring") then
          category = "string"
        elseif group_name:match("[Ff]unction") then
          category = "function"
        elseif group_name:match("[Kk]eyword") or group_name:match("[Ss]tatement") then
          category = "keyword"
        elseif group_name:match("[Tt]ype") then
          category = "type"
        elseif group_name:match("[Nn]umber") or group_name:match("[Cc]onstant") then
          category = "number"
        elseif group_name:match("[Ww]arn") then
          category = "warn"
        elseif group_name:match("[Ii]nfo") or group_name:match("[Ss]pecial") then
          category = "info"
        elseif group_name:match("[Ee]rror") then
          category = "error"
        end

        if category and not color_map[category] then
          color_map[category] = hex
        end
      end
    end
  end

  -- Build result in order
  local color_order = { "bg", "comment", "string", "function", "keyword", "type", "number", "warn", "info", "error" }
  for _, cat in ipairs(color_order) do
    if color_map[cat] then
      colors[cat] = color_map[cat]
    end
  end

  return colors
end

---Try to load a colorscheme plugin via lazy.nvim
---@param theme string
function M.ensure_theme_loaded(theme)
  -- Try to load via lazy.nvim if available
  local ok, lazy = pcall(require, "lazy")
  if ok and lazy then
    -- Map theme names to plugin names
    local plugin_map = {
      tokyonight = "tokyonight.nvim",
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
      onedark = "onedarkpro.nvim",
      ["night-owl"] = "night-owl.nvim",
      ["solarized-osaka"] = "solarized-osaka.nvim",
      ayu = "neovim-ayu",
      ["ayu-dark"] = "neovim-ayu",
      ["ayu-light"] = "neovim-ayu",
      ["ayu-mirage"] = "neovim-ayu",
      palenight = "palenight.nvim",
      everblush = "nvim",
    }

    local plugin_name = plugin_map[theme]
    if plugin_name then
      pcall(function()
        require("lazy").load({ plugins = { plugin_name } })
      end)
    end
  end
end

---Extract all palettes with proper colorscheme switching
---@param theme_names string[]
---@return table<string, table>, string[]
function M.extract_all_palettes(theme_names)
  local palettes = {}
  local valid_themes = {}
  local original_scheme = vim.g.colors_name

  -- Save current state
  local saved_bg = vim.o.background

  for _, theme in ipairs(theme_names) do
    -- Ensure plugin is loaded for lazy.nvim users
    M.ensure_theme_loaded(theme)

    -- Clear all highlights first to ensure clean state
    vim.cmd("highlight clear")

    -- Apply colorscheme
    local ok = pcall(vim.cmd, "colorscheme " .. theme)

    if ok then
      -- Check if colorscheme was actually applied
      local current = vim.g.colors_name
      -- Some colorschemes set a different name (e.g., catppuccin-mocha -> catppuccin)
      if current and (current == theme or current:find(theme, 1, true) or theme:find(current, 1, true)) then
        -- Extract colors from current state
        local colors = extract_current_colors()

        if colors and vim.tbl_count(colors) >= 3 then
          palettes[theme] = colors
          table.insert(valid_themes, theme)
        end
      end
    end
  end

  -- Restore original colorscheme
  vim.o.background = saved_bg
  if original_scheme then
    M.ensure_theme_loaded(original_scheme)
    pcall(vim.cmd, "colorscheme " .. original_scheme)
  end

  table.sort(valid_themes)
  return palettes, valid_themes
end

---Check if colorscheme has light background
---@param colors table
---@return boolean
function M.is_light_theme(colors)
  local bg = colors.bg
  if not bg or type(bg) ~= "string" or #bg < 7 then
    return false
  end

  -- Parse hex color
  local r = tonumber(bg:sub(2, 3), 16)
  local g = tonumber(bg:sub(4, 5), 16)
  local b = tonumber(bg:sub(6, 7), 16)

  if not r or not g or not b then
    return false
  end

  -- Calculate relative luminance
  local luminance = 0.299 * (r / 255) + 0.587 * (g / 255) + 0.114 * (b / 255)
  return luminance > 0.5
end

---Get ordered swatch colors from palette
---@param colors table
---@return string[]
function M.get_swatch_colors(colors)
  if not colors then
    return {}
  end

  local order = {
    "bg",
    "comment",
    "string",
    "function",
    "keyword",
    "type",
    "number",
    "warn",
    "info",
    "error",
  }

  local swatches = {}
  local seen = {}

  for _, key in ipairs(order) do
    local color = colors[key]
    if color and type(color) == "string" and not seen[color] then
      table.insert(swatches, color)
      seen[color] = true
    end
  end

  return swatches
end

---Get list of available colorschemes
---@return string[]
function M.get_available_colorschemes()
  local colorschemes = vim.fn.getcompletion("", "color")
  -- Filter out common unwanted entries (Neovim built-in defaults)
  local filtered = {}
  local exclude = {
    default = true,
    blue = true,
    darkblue = true,
    delek = true,
    desert = true,
    elflord = true,
    evening = true,
    habamax = true,
    industry = true,
    koehler = true,
    lunaperche = true,
    morning = true,
    murphy = true,
    pablo = true,
    peachpuff = true,
    quiet = true,
    retrobox = true,
    ron = true,
    shine = true,
    slate = true,
    sorbet = true,
    torte = true,
    wildcharm = true,
    zaibatsu = true,
    zellner = true,
    vim = true,
  }

  for _, scheme in ipairs(colorschemes) do
    if not exclude[scheme] then
      table.insert(filtered, scheme)
    end
  end

  table.sort(filtered)
  return filtered
end

return M
