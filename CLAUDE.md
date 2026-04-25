# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Linear 風の問い合わせ管理アプリ。シングルユーザー・1ボード固定・認証なし。

詳細な要件定義は [docs/requirements.md](docs/requirements.md) を参照。

## 起動コマンド

### Docker (MySQL)
```bash
# プロジェクトルートで実行
docker-compose up -d
# → MySQL が localhost:3306 で起動
# 停止: docker-compose down
# データも含めて完全リセット: docker-compose down -v
```

### バックエンド (Rails API)
```bash
cd backend
bundle install             # 初回のみ
bundle exec rails db:prepare   # 初回・マイグレーション反映時
bundle exec rails server -p 3001
# → http://localhost:3001
```

### フロントエンド (Next.js)
```bash
cd frontend
npm install                # 初回のみ
npm run dev
# → http://localhost:3000
```

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

PR テンプレートと関連 Issue のすべてのチェックボックスがチェックされていること。`check-pr-checkboxes` / `check-issue-checkboxes` が pass しない限りマージ不可。


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
└── frontend/               Next.js 15 App Router
    ├── app/
    │   ├── page.tsx           カンバンボード（ルート）
    │   ├── settings/          プロパティ管理画面
    │   └── layout.tsx
    ├── components/
    │   ├── Board.tsx          DndContext のルート、全体レイアウト
    │   ├── StatusColumn.tsx   各ステータス列、SortableContext
    │   ├── InquiryCard.tsx    問い合わせカード、Draggable
    │   └── InquiryModal.tsx   問い合わせ詳細編集モーダル（Portal）
    ├── lib/api/              Rails API クライアント（fetch ベース）
    └── types/
```

### データフロー

- フロントエンドは **TanStack Query** でサーバー状態を管理。`GET /api/inquiries` の結果がアプリ全体の真実のデータ源。
- DnD 操作（@dnd-kit）で問い合わせをドロップすると `PATCH /api/inquiries/{id}/move` を呼び出し、楽観的更新後にクエリを revalidate。
- 問い合わせ・ステータスの並び順は `position` (INTEGER) で管理。移動時は影響する行の position をトランザクション内で一括更新。

### バックエンド規約

- Rails API mode。View 層は持たず JSON のみ返す。
- CORS は 開発時 `http://localhost:3000` のみ許可、本番は EC2 のフロント配信オリジンを追加。
- `GET /api/inquiries` は inquiries → status / priority / labels を includes して返す（N+1 対策）。
- JSON キーは **camelCase** で返す（Next.js 側との親和性）。`jsonapi-serializer` で一元化。
- マスアサインメント対策は Strong Parameters で明示。

### API ベース URL

| 環境 | URL |
|------|-----|
| バックエンド | http://localhost:3001/api |
| フロントエンド | http://localhost:3000 |
