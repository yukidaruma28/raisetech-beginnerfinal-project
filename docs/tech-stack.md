# 技術スタック定義書

## 概要

| 項目 | 内容 |
|------|------|
| フロントエンド | Next.js 16（App Router）+ TypeScript |
| バックエンド | Ruby on Rails 8.1（API mode） |
| データベース | MySQL 8 |
| 通信方式 | REST API（JSON） |
| インフラ | Docker + AWS EC2 + RDS（既存 raisetech_kanban と同居） |

本アプリは既存 raisetech_kanban（Spring Boot + React + PostgreSQL）との**技術スタック差分を最大化**する方針で選定している。ポートフォリオとして「異なる言語・異なるフレームワーク・異なる DB」を経験できることを優先する。

---

## フロントエンド

### コア

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| Next.js | 16 | App Router + RSC + Server Actions の最新構成。SSR/SSG/ISR を選択可能で、ポートフォリオ価値が高い |
| React | 19 | Next.js 16 が要求。Concurrent Features が安定版 |
| TypeScript | 5 | 型安全。API レスポンス型・DnD イベント型の明示でバグを早期検出 |

### ビルド・開発環境

| ツール | バージョン | 選定理由 |
|-------|---------|---------|
| Node.js | 22 LTS | Next.js 16 が要求する最低ラインを満たす Active LTS |
| npm | 10+ | パッケージマネージャー。Next.js 公式例が npm 中心のため揃える |

### スタイリング

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| Tailwind CSS | 4 | ユーティリティファースト CSS。Linear 風の細かい UI 調整と相性が良い |
| shadcn/ui | 最新 | Radix UI + Tailwind ベースのコンポーネント集。モーダル・セレクト・ダイアログを素早く整え、Linear 風の洗練された見た目を低コストで実現する（コピー配布方式のためロックインなし） |
| lucide-react | 最新 | アイコンセット。shadcn/ui と相性良、Linear 的アイコン表現に使う |

### 状態管理・通信

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| TanStack Query | 5 | サーバー状態管理。キャッシュ・再取得・楽観的更新を宣言的に記述できる。既存 raisetech_kanban でも採用しており、学習の連続性を確保 |
| fetch（標準 API） | - | Next.js 16 の `fetch` + キャッシュ制御を優先。Axios は採用せず軽量に保つ |

### フォーム・バリデーション

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| React Hook Form | 7 | 非制御コンポーネントベースで再レンダー最小。問い合わせフォームとモーダル入力に適合 |
| zod | 4 | TypeScript 型と同期するバリデーションスキーマ。API レスポンス検証にも流用可能 |

### ドラッグ＆ドロップ

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| @dnd-kit/core | 6 | アクセシビリティ対応 DnD。既存 raisetech_kanban でも採用実績あり、学習コストが低い |
| @dnd-kit/sortable | 10 | ステータス列内・列間のソータブル UI を宣言的に構築 |

### コード品質

| ツール | 用途 |
|-------|------|
| ESLint | 静的解析。Next.js 公式推奨設定を使用 |
| Prettier | コードフォーマット統一 |

### テスト

| ライブラリ | 用途 |
|-----------|------|
| Vitest | ユニットテストランナー |
| React Testing Library | コンポーネントの振る舞いテスト |
| Playwright | E2E テスト（必要に応じて採用） |

---

## バックエンド

### コア

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| Ruby | 3.4 | active maintenance 中の最新パッチ系列。YJIT が標準有効でパフォーマンス良好。Rails 8.1 の推奨ライン |
| Rails | 8.1（API mode） | フロントと分離した API 専用モード。ビュー層を持たず軽量。`rails new backend --api --database=mysql` で生成。Solid Queue / Cache / Cable と Kamal が同梱され、別 gem を入れずに job キュー・キャッシュ・本番デプロイの足回りが揃う |

### Web / API

| モジュール | 用途 |
|-----------|------|
| ActionController::API | REST コントローラー・JSON レスポンス |
| Rails Strong Parameters | マスアサインメント対策・許可属性の明示 |

### データアクセス

| ライブラリ | 用途 |
|-----------|------|
| ActiveRecord | ORM。Rails 標準 |
| mysql2 | MySQL 接続ドライバー |

### JSON シリアライズ

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| jsonapi-serializer | 最新 | 高速・宣言的な JSON 整形。キャメルケース変換を一元化し、Next.js 側と API 形式を揃える |

### CORS

| ライブラリ | 用途 |
|-----------|------|
| rack-cors | Next.js（3000）と本番フロントからのリクエストのみ許可 |

### DB マイグレーション

| ツール | 選定理由 |
|-------|---------|
| ActiveRecord Migration | Rails 標準。`db/migrate/` に Ruby で記述。既存の Flyway とは書き方が大きく異なるが、ロールバックサポートや scaffold との統合で開発効率が高い |

### 環境変数

| ライブラリ | 用途 |
|-----------|------|
| dotenv-rails | `.env` からの環境変数読み込み（開発・テスト用） |

### テスト

| ライブラリ | 用途 |
|-----------|------|
| RSpec Rails | ユニットテスト・リクエストテスト。Rails コミュニティで標準的 |
| FactoryBot | テストデータ生成 |
| database_cleaner-active_record | テスト間の DB クリーンアップ |

### 静的解析・フォーマット

| ツール | 用途 |
|-------|------|
| RuboCop | Ruby の静的解析・フォーマット。`rubocop-rails` プラグイン併用 |
| Brakeman | セキュリティ静的解析 |

---

## データベース

| 項目 | 内容 |
|------|------|
| DBMS | MySQL 8.0 |
| DB 名 | `inquiry_tracker` |
| 接続 | ローカル：`localhost:3306` / 本番：既存 RDS エンドポイント |
| 文字コード | `utf8mb4` / 照合順序 `utf8mb4_0900_ai_ci` |
| マイグレーション管理 | ActiveRecord Migration（`db/migrate/` に配置） |

---

## 開発環境・インフラ

| ツール | 用途 |
|-------|------|
| Docker | backend / mysql の2コンテナを管理（frontend はホスト側で `npm run dev`） |
| Docker Compose v2 | `docker-compose.yml` で開発時の起動を一本化 |
| Git | バージョン管理 |
| GitHub | リモートリポジトリ |
| GitHub Actions | CI（lint / test 実行）。既存 raisetech_kanban の構成を参考に設定 |
| Terraform | AWS リソース（EC2 / セキュリティグループ / RDS のユーザー・DB）を IaC 化 |
| AWS EC2 | 本番アプリケーションサーバー。既存インスタンスと共存 |
| AWS RDS MySQL | 本番 DB。既存インスタンス内に新 DB `inquiry_tracker` を作成して同居運用 |

### Rails をコンテナ内で動かす理由

Rails の bundle install / db:prepare / rails server は **必ず `inquiry_backend` コンテナ内で実行**する（`docker compose exec backend ...`）。Windows + MySQL Shell 8.0 同梱の libmysqlclient が GSSAPI モジュール参照で破損しており、ホスト直接の `bundle exec rails ...` では `mysql2` 経由で必ず認証エラーになるため。Linux ベースのコンテナ内では同問題は発生しない。

frontend は libmysqlclient に依存しないため、ホスト側で `npm run dev` を実行する従来通りの開発フロー。

---

## ポート割当

| サービス | ローカル | 本番 |
|---------|---------|------|
| Next.js | 3000 | 80 / 443（Nginx 前段） |
| Rails API | 3001 | 内部ポートのみ |
| MySQL | 3306 | RDS エンドポイント |

ポート 3000 を Next.js に割り当てるため、Rails のデフォルト 3000 を 3001 に変更する。

---

## バージョン整合性メモ

| 組み合わせ | 確認事項 |
|-----------|---------|
| Next.js 16 + React 19 | Next.js 16 は React 19 を要求 |
| Next.js 16 + Tailwind CSS 4 | Tailwind 4 は PostCSS プラグイン（`@tailwindcss/postcss`）の利用に移行済み。`create-next-app` のデフォルト設定で対応 |
| Next.js 16 + Turbopack | `next dev` のデフォルトは Turbopack だが、マルチバイトを含むパス（`デスクトップ` 等）でパニックする既知バグがあるため、本プロジェクトでは `next dev --webpack` を採用 |
| Rails 8.1 + Ruby 3.4 | 完全対応。Solid Queue / Cache / Cable と Kamal がデフォルト同梱 |
| Rails 8.1 + mysql2 | `mysql2` 0.5 系で動作。MySQL 8 の `caching_sha2_password` で接続できない環境（特に Windows）では、サーバー側で `mysql_native_password` をデフォルト認証に切替して回避（`docker-compose.yml` の `command` で指定済み） |
| jsonapi-serializer + ActiveRecord | `belongs_to` / `has_many` の eager_load を serializer 側で明示する |
| @dnd-kit/core 6 + @dnd-kit/sortable 10 | core v6 と sortable v10 の組み合わせで動作確認済み（既存 raisetech_kanban と同じ） |
| zod 4 | v3 から API が一部変更（`z.string().email()` → `z.email()` など）。v3 系のスニペットを流用する際は注意 |

---

## 採用しないことを明示する技術（判断の履歴）

| 技術 | 不採用理由 |
|------|----------|
| Spring Boot / Java | 既存 raisetech_kanban で採用済み。スタック差分化が目的のため除外 |
| PostgreSQL | 同上 |
| Vite + React（SPA 構成） | 同上。Next.js に移行することで App Router / RSC の学習が加わる |
| Server Actions 主体の構成 | バックエンドが Rails のため、Next.js 側は API クライアントとしての役割に徹する。Server Actions は将来的に一部 UI で検証する余地はある |
| Devise / 認証系 Gem | 認証なしのため不要 |
| ActionCable | リアルタイム同期は MVP 対象外 |
