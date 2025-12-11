# spectra.nvim

[English](README.md)

NvChad風のカラーパレットプレビュー付きNeovimカラースキームピッカー

![Neovim](https://img.shields.io/badge/Neovim-0.9+-green.svg)

<img width="2632" height="1729" alt="features" src="https://github.com/user-attachments/assets/8f390eea-31e4-4253-b298-4a5a2813fa69" />

## 要件

- Neovim >= 0.9.0
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)

## インストール

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

## 設定

```lua
require("spectra").setup({
  -- 表示するカラースキームのリスト（nil = 自動検出）
  themes = nil,

  -- ポップアップのサイズ
  width = 50,
  height = 15,

  -- ボーダースタイル（"rounded", "single", "double" など）
  border = "rounded",

  -- ナビゲーション中のライブプレビューを有効化
  live_preview = true,

  -- 選択したカラースキームをセッション間で永続化
  persist = true,
})
```

## キーバインド

| キー | アクション |
|-----|--------|
| `j` / `<Down>` / `<C-j>` / `<C-n>` | 次のテーマ |
| `k` / `<Up>` / `<C-k>` / `<C-p>` | 前のテーマ |
| `<CR>` | 選択したテーマを適用 |
| `<Esc>` / `q` / `<C-c>` | キャンセル（元に戻す） |
| 文字入力 | テーマをフィルター |

## コマンド

- `:Spectra` - カラースキームピッカーを開く
- `:SpectraRefresh` - カラーパレットキャッシュを更新
