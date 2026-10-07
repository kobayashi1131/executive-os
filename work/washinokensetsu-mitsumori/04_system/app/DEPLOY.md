# 見積作成アプリの公開手順

GitHub → Cloudflare Workers（静的ファイルのみ）。ログインなしでURLを開けば使える。

## 公開するファイル（このフォルダの4つ）

| ファイル | 中身 | gitに入るか |
|---|---|---|
| `index.html` | アプリ本体 | 入る |
| `genshi.local.xltx` | 見積書の原紙（1ページに収まるよう直したもの。社印・口座入り） | **入らない**（`.local` なので） |
| `robots.txt` | 検索エンジンに載せない設定 | 入る |
| `.assetsignore` | `.git` を公開しない設定 | 入る |

`genshi.local.xltx` はgitに入らないので、GitHubへは手でアップロードする。

## 守ること

- GitHubのリポジトリは **必ず Private**（原紙が入るため）
- URLは社内の人にだけ教える。URLを知っていれば誰でも開ける
- Cloudflareのプロジェクト名がURLになるので、推測されにくい名前にする（下の例）

---

## 手順1: GitHubにリポジトリを作る

1. `github.com` にログイン
2. 右上の「**+**」→「**New repository**」
3. Repository name: `washino-mitsumori-ef296a`（末尾の英数字は推測されにくくするため）
4. **Private を選ぶ**（Publicは不可）
5. 「**Create repository**」
6. 「**uploading an existing file**」をクリック
7. このフォルダの4つ（`index.html` / `genshi.local.xltx` / `robots.txt` / `.assetsignore`）をまとめてドラッグ＆ドロップ
   - フォルダの場所: `executive-os\work\washinokensetsu-mitsumori\04_system\app\`
   - `DEPLOY.md`（この手順書）は上げなくていい
8. 「**Commit changes**」

## 手順2: Cloudflareにつなぐ（2026-10-07 実施済み）

Cloudflareの画面に「Pages」が出なかったので **Workers** で公開した。

- 公開URL: `https://washino-mitsumori-ef296a.s-koba-cc3.workers.dev`
- GitHub連携: `github.com/settings/installations` →「Cloudflare Workers and Pages」→ Configure で `washino-mitsumori-ef296a` を許可
- Build command: 空欄
- Deploy command: `npx wrangler deploy --assets=. --name=washino-mitsumori-ef296a --compatibility-date=2026-10-01`
- `.assetsignore` で `.git` などを公開対象から外している（これが無いと `/.git/` がURLから見える）

## 手順3: スマホで確認

1. スマホでURLを開く
2. 「明細」に1行入れて「原紙に書き込んでExcelを作る」
3. 共有画面（またはダウンロード）が出て、見積書の形のExcelが開ければOK
4. ホーム画面に追加しておくとアプリのように開ける（Safari: 共有ボタン →「ホーム画面に追加」）

---

## あとで直したとき（更新）

IA子が `index.html` を直したら、GitHubのリポジトリ画面で「Add file」→「Upload files」から同じ名前で上げ直す。上げると1分ほどで自動で反映される。

原紙を変えたいときも同じで、新しい原紙を `genshi.local.xltx` という名前にして上げ直す。端末ごとに一時的に変えたいだけなら、アプリの ⚙設定 →「別の原紙にする」でよい。
