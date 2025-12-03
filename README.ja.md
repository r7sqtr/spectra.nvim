# spectra.nvim

[English](README.md)

NvChad風のカラーパレットプレビュー付きNeovimカラースキームピッカー

![Neovim](https://img.shields.io/badge/Neovim-0.9+-green.svg)

## 要件

- Neovim >= 0.9.0
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)

## インストール

### lazy.nvim

```lua
{
  dir = "r7sqtr/spectra.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  lazy = true,
  cmd = "Spectra",
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

## ライセンス

MIT
