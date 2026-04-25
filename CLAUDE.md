# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Linear 風の問い合わせ管理アプリ。シングルユーザー・1ボード固定・認証なし。

詳細な要件定義は [docs/requirements.md](docs/requirements.md) を参照。

## 起動コマンド

### Docker (MySQL + Rails)

バックエンド（Rails）と DB（MySQL）はすべて Docker 上で動かす。Windows の libmysqlclient 互換問題を回避するため、Rails コンテナ内で `bundle install` / `rails server` を実行する設計。

```bash
# プロジェクトルートで実行
docker-compose up -d
# → MySQL が localhost:3306、Rails API が localhost:3001 で起動
# 停止: docker-compose down
# データも含めて完全リセット: docker-compose down -v
```

初回起動時は `inquiry_backend` コンテナの中で `bundle install` → `rails db:prepare` → `rails server` が自動実行されるため、起動完了まで数分かかる。

### Rails コマンドの実行方法

ホスト側で `bundle exec rails ...` を直接実行するのではなく、コンテナ越しに発行する:

```bash
docker compose exec backend bundle exec rails console
docker compose exec backend bundle exec rails db:migrate
docker compose exec backend bundle exec rspec
docker compose exec backend bundle exec bin/rails generate model Foo
```

### フロントエンド (Nuxt 4 / Vue 3)
```bash
cd frontend
npm install                # 初回のみ
npm run dev
# → http://localhost:3000
```

API ベース URL は `frontend/.env` の `NUXT_PUBLIC_API_BASE_URL`（デフォルト: `http://localhost:3001`）で切替可能。`nuxt.config.ts` の `runtimeConfig.public.apiBaseUrl` から参照する。

### ポート競合が起きた場合

サーバー起動前に対象ポートが使用中の場合は、既存プロセスを kill してから起動する。

- **フロントエンド（3000）**: `npx kill-port 3000`
- **バックエンド（3001）**: `npx kill-port 3001`

### Git フック（初回クローン後に必須）
```bash
# プロジェクトルートで実行
git config core.hooksPath .githooks
# → main への直接プッシュがブロックされるようになる
```

## 開発フロー

### ブランチ命名規則

```
feature/{番号}-{説明}   # 機能追加
fix/{番号}-{説明}       # バグ修正
chore/{番号}-{説明}     # 設定・ドキュメント・依存関係
docs/{番号}-{説明}      # ドキュメントのみの変更
```

例: `feature/12-add-inquiry-comment`

### 開発の流れ

1. `/go {機能説明}` を実行（または自然言語で依頼）→ go スキルが自動で以下を処理
2. Plan モードでプランを作成・承認
3. GitHub Issue を作成
4. `git checkout main && git pull origin main` → ブランチ作成
5. 実装・コミット
6. PR を作成（タイトル・本文は下記規則に従う）
7. GitHub Actions のチェックがすべて通ることを確認
8. PR をマージ → Issue が自動クローズ・ブランチが自動削除

### 実装着手の前提条件（必須・例外なし）

コードを書き始める前に、この順序で必ず完了すること：

1. `gh issue create` で GitHub Issue を作成し、Issue 番号を取得する
2. `git checkout main && git pull origin main` を実行する
3. `git checkout -b feature/{Issue番号}-{slug}` でブランチを作成する

Issue 番号のないブランチで実装を開始してはならない。`/go` スキルを使うと上記が自動化される。

### PR タイトル・本文の規則

**タイトル形式：**

```
feat: {機能名}-#{Issue番号}
fix: {修正内容}-#{Issue番号}
chore: {変更内容}-#{Issue番号}
docs: {変更内容}-#{Issue番号}
```

例: `feat: 問い合わせ作成機能-#21`

**本文の必須記載（冒頭の関連 Issue 欄）：**

```
issue #{Issue番号}
Closes #{Issue番号}
```

`issue #番号` が参照リンク、`Closes #番号` がマージ時の自動クローズを担う。

**マージの条件：**

- PR テンプレートと関連 Issue のすべてのチェックボックスがチェックされていること（`check-pr-checkboxes` / `check-issue-checkboxes` が pass）。
- `backend-ci.yml`（RSpec / RuboCop / Brakeman）と `frontend-ci.yml`（ESLint / `nuxi typecheck`）がすべて green であること。バックエンド変更を含む PR は backend-ci が、フロントエンド変更を含む PR は frontend-ci が走る。

### CI と同じチェックをローカルで走らせる

PR を出す前に必ず以下を実行し、すべて pass / 違反 0 を確認する。

```bash
# Backend（docker compose 起動済み前提）
docker compose exec backend bundle exec rspec
docker compose exec backend bundle exec rubocop
docker compose exec backend bundle exec brakeman --no-pager --quiet

# Frontend
cd frontend && npm run lint
cd frontend && npx nuxi typecheck
```


## アーキテクチャ

### ディレクトリ構成
```
<repo-root>/
├── backend/                Rails 7.1 API mode
│   ├── app/
│   │   ├── controllers/api/   REST APIエンドポイント（inquiries / statuses / priorities / labels）
│   │   ├── models/            ActiveRecord モデル
│   │   └── serializers/       jsonapi-serializer による JSON 整形
│   ├── config/
│   │   ├── database.yml       MySQL 接続設定
│   │   ├── routes.rb          /api 以下の resources
│   │   └── initializers/cors.rb
│   └── db/
│       ├── migrate/
│       └── seeds.rb           Linear 準拠の初期ステータス・優先度
└── frontend/               Nuxt 4（Vue 3 / SSR + SPA）
    ├── app/
    │   ├── app.vue            アプリのエントリ（ヘッダー + メイン）
    │   ├── components/
    │   │   ├── ui/            shadcn-vue のコンポーネント
    │   │   └── board/
    │   │       ├── StatusColumns.vue  ステータス列ヘッダー
    │   │       ├── InquiryCard.vue    問い合わせカード（予定）
    │   │       └── InquiryModal.vue   問い合わせ詳細モーダル（予定）
    │   ├── lib/api/           Rails API クライアント（fetch ベース）
    │   ├── plugins/           Nuxt プラグイン（vue-query 等）
    │   ├── assets/css/        Tailwind v4 エントリ
    │   └── types/             型定義
    ├── nuxt.config.ts         Nuxt の設定（モジュール / 環境変数 / Vite プラグイン）
    └── components.json        shadcn-vue の設定
```

### データフロー

- フロントエンドは **@tanstack/vue-query** でサーバー状態を管理。`GET /api/inquiries` の結果がアプリ全体の真実のデータ源。
- DnD 操作（vue-draggable-plus）で問い合わせをドロップすると `PATCH /api/inquiries/{id}/move` を呼び出し、楽観的更新後にクエリを revalidate。
- 問い合わせ・ステータスの並び順は `position` (INTEGER) で管理。移動時は影響する行の position をトランザクション内で一括更新。

### バックエンド規約

- Rails API mode。View 層は持たず JSON のみ返す。
- CORS は 開発時 `http://localhost:3000` のみ許可、本番は EC2 のフロント配信オリジンを追加。
- `GET /api/inquiries` は inquiries → status / priority を includes して返す（N+1 対策）。
- JSON キーは **camelCase** で返す（Vue/Nuxt 側との親和性）。`jsonapi-serializer` で一元化。
- マスアサインメント対策は Strong Parameters で明示。
- Priority は 3 段階運用（1=高 / 2=中 / 3=低）。`inquiries.priority_id` は NOT NULL（デフォルト「低」）。Label / assignee は MVP スコープ外（`docs/tech-stack.md` 参照）。

### 実装済み API エンドポイント

| Method | Path | 用途 |
|---|---|---|
| GET | /api/statuses | ステータス一覧（position 昇順）|
| GET | /api/priorities | 優先度一覧（position 昇順、3 件）|
| GET | /api/inquiries | 問い合わせ一覧（status_id / priority_id eager load 済み）|
| POST | /api/inquiries | 問い合わせ作成（priorityId 省略時「低」自動割当、position は同 status 内 MAX+1 自動採番、201 / 422 / 404 / 400）|
| PATCH | /api/inquiries/:id | 問い合わせ部分更新（送信されたフィールドのみ反映、position 据え置き、200 / 422 / 404）|
| DELETE | /api/inquiries/:id | 問い合わせ削除（物理削除、204 / 404）|

### API ベース URL

| 環境 | URL |
|------|-----|
| バックエンド | http://localhost:3001/api |
| フロントエンド | http://localhost:3000 |
