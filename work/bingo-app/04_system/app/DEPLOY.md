# 大阪ビンゴ合戦 本番アプリ デプロイ手順

わしの建設のアプリと同じ方式（フロントはCloudflare Pages、データ保存はGoogle Apps Script + スプレッドシート相当）。Claudeアカウント不要で、誰でもURLを開くだけで使える。

## 全体像

```text
みんなのスマホ (index.html を開く)
        │  数秒おきに読み書き
        ▼
Google Apps Script (Code.gs をWebアプリとして公開)
        │  保存先
        ▼
スクリプトプロパティ（ゲーム状態のJSONを1つだけ保存）
```

- `index.html`：見た目と操作。Cloudflare Pagesで公開する（GitHub経由）。
- `Code.gs`：データの保存・読み出しだけを行う最小限のバックエンド。Googleアカウントで動かす。

## 手順1: Google Apps Script をデプロイする

1. https://script.google.com/ を開く（Googleアカウントでログイン）。
2. 「新しいプロジェクト」を作成。
3. デフォルトで開かれる `Code.gs` の中身を全部消して、このリポジトリの
   `work/bingo-app/04_system/app/Code.gs` の内容を貼り付ける。
4. 右上の「デプロイ」→「新しいデプロイ」。
5. 種類の選択で「ウェブアプリ」を選ぶ。
6. 設定:
   - 説明: 何でもよい（例: bingo-app v1）
   - 次のユーザーとして実行: **自分**
   - アクセスできるユーザー: **全員**
7. 「デプロイ」を押す。初回はGoogleの確認画面が出るので許可する。
8. 発行されたURL（`https://script.google.com/macros/s/.../exec` の形）をコピーする。
   → これが `GAS_URL` になる。

**注意:** `Code.gs` を後で修正したときは、「デプロイ」→「デプロイを管理」→ 既存のデプロイを編集 → バージョンを「新バージョン」にして再デプロイしないと反映されない。

## 手順2: index.html にGAS_URLを設定する

`work/bingo-app/04_system/app/index.html` を開き、`<script>` タグの中の

```js
var GAS_URL = 'PASTE_YOUR_GAS_WEB_APP_URL_HERE';
```

の部分を、手順1で発行されたURLに書き換える。

## 手順3: Cloudflare Pages で公開する

わしの建設のアプリと同じ流れ。

1. GitHubに新しいリポジトリを作る（Private推奨。例: `bingo-app`）。
2. `work/bingo-app/04_system/app/index.html` をそのリポジトリのルートに `index.html` としてアップロードする（GitHubのWeb画面から Add file → Upload files でOK）。
3. Cloudflareダッシュボード → Workers & Pages → 「Pagesを作成」→「Gitに接続」でそのリポジトリを選択。
4. ビルド設定は不要（静的HTML1枚なので、ビルドコマンドは空でよい）。
5. デプロイ完了後に発行されるURL（例: `https://bingo-app.pages.dev`）を、参加する友達に共有する。

## 動作確認（当日より前に必ず）

1. 発行されたURLを2台の端末（別々の回線でもOK）で開く。
2. 片方でマスをタップして「達成」にする。
3. もう片方の画面を更新（または最大4秒待つ）して、同じ状態になっているか確認する。
4. 項目プールの追加・削除、共通ミッションのチェック、強制ミッションの送信も一通り試す。

問題なければ当日はURLを共有するだけで全員が使える。

## 既知の制約

- 保存先（スクリプトプロパティ）は容量が小さいので、写真は保存しない設計にしてある（達成報告はLINEで）。
- 複数人が同時に同じ内容を編集すると、最後に保存した内容が勝つ（後勝ち）。取り合いになるほど頻繁な同時編集は想定していない。
- 自動更新は4秒間隔。リアルタイムではなく「ほぼリアルタイム」。
