# Design Tokens

`data/ui/examples/system-components.css` のCSS変数として実装されている値の一覧と、その意図。新しい画面・モックを作る時は、ここにある値だけを使う（都度新しい色やサイズを増やさない）。

## 色

### ベース（背景・文字・境界線）

| トークン | 値 | 用途 |
|---|---|---|
| `--color-bg` | #F7F8FA | ページ全体の背景 |
| `--color-surface` | #FFFFFF | カード・テーブル・入力欄の背景 |
| `--color-border` | #E1E4E8 | 罫線、カードの境界線 |
| `--color-text` | #1F2937 | 本文の文字色 |
| `--color-text-muted` | #6B7280 | 補足・ラベル・注釈の文字色 |
| `--color-text-inverse` | #FFFFFF | 濃い背景の上の文字色 |

### プライマリ（操作・強調）

| トークン | 値 | 用途 |
|---|---|---|
| `--color-primary` | #1D4ED8 | 主要ボタン、リンク、選択状態 |
| `--color-primary-hover` | #1E40AF | 主要ボタンのhover |
| `--color-primary-soft` | #EFF4FF | 選択中の行・タブの背景 |

### 状態色（成功・注意・危険・情報）

| トークン | 値 | 用途 |
|---|---|---|
| `--color-success` | #15803D | 受注・完了・成功 |
| `--color-success-bg` | #E7F6EC | 成功系バッジの背景 |
| `--color-warning` | #B45309 | 未確定・保留・注意 |
| `--color-warning-bg` | #FDF3E3 | 注意系バッジの背景 |
| `--color-danger` | #B91C1C | 失注・エラー・削除 |
| `--color-danger-bg` | #FBEAEA | 危険系バッジの背景 |
| `--color-info` | #0E7490 | 案内・補足情報 |
| `--color-info-bg` | #E7F6F8 | 情報系バッジの背景 |

## タイポグラフィ

- フォント：`"Yu Gothic", "Hiragino Sans", system-ui, sans-serif`（Office文書・BCPカード等と統一）
- 基準サイズ：16px（本文）

| トークン | サイズ | 用途 |
|---|---|---|
| `--font-size-xs` | 12px | 補足・キャプション |
| `--font-size-sm` | 14px | ラベル、テーブル本文 |
| `--font-size-base` | 16px | 本文 |
| `--font-size-lg` | 20px | セクション見出し |
| `--font-size-xl` | 28px | KPI数値、ページタイトル |

## 余白・角丸・影

| トークン | 値 |
|---|---|
| `--space-1` | 4px |
| `--space-2` | 8px |
| `--space-3` | 12px |
| `--space-4` | 16px |
| `--space-6` | 24px |
| `--space-8` | 32px |
| `--radius-sm` | 6px（ボタン・バッジ） |
| `--radius-md` | 10px（カード・入力欄） |
| `--shadow-card` | `0 1px 2px rgba(16,24,40,.06), 0 1px 3px rgba(16,24,40,.1)` |

## ブレークポイント

- 768px未満：モバイル表示に切り替える（`data/ui/README.md`のスマホ対応方針に準拠）

## 使い方

1. HTMLモックの `<head>` で `data/ui/examples/system-components.css` を読み込む。
2. `component-inventory.md` にある部品名に対応するクラス（`.btn`, `.card`, `.kpi-card`, `.badge`, `.data-table` など）を使う。
3. 色や余白を直接指定したくなったら、まずこの一覧に無いか確認する。無ければ本当に必要か検討してから追加する。
