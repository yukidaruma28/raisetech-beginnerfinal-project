# 技術スタック定義書

## 概要

| 項目 | 内容 |
|------|------|
| フロントエンド | Nuxt 4（Vue 3 / SSR + SPA 混在）+ TypeScript |
| バックエンド | Ruby on Rails 8.1（API mode） |
| データベース | MySQL 8 |
| 通信方式 | REST API（JSON） |
| インフラ | Docker + AWS EC2 + RDS（専用インスタンス、Terraform で完全管理） |

本アプリは既存 raisetech_kanban（Spring Boot + React + PostgreSQL）との**技術スタック差分を最大化**する方針で選定している。ポートフォリオとして「異なる言語・異なるフレームワーク・異なる DB」を経験できることを優先する。

---

## フロントエンド

### コア

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| Nuxt | 4 | Vue 3 のメタフレームワーク。ファイルベースルーティング・SSR・モジュール機構を備え、Next.js 相当のフルスタック構成を Vue で実現できる |
| Vue | 3 | Composition API による宣言的な UI。React と並ぶ二大スタックで国内求人多く、ポートフォリオ価値が高い |
| TypeScript | 5 | 型安全。API レスポンス型・DnD イベント型の明示でバグを早期検出 |

### ビルド・開発環境

| ツール | バージョン | 選定理由 |
|-------|---------|---------|
| Node.js | 22 LTS | Nuxt 4 が要求する最低ラインを満たす Active LTS |
| npm | 10+ | パッケージマネージャー。Nuxt 公式例が npm/pnpm 中心。本プロジェクトは npm に統一 |
| Vite | 7 | Nuxt 4 が内部で利用するビルドツール。Turbopack のような独自バンドラーと違い、マルチバイトを含むパスでも安定動作する |

### スタイリング

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| Tailwind CSS | 4 | ユーティリティファースト CSS。Linear 風の細かい UI 調整と相性が良い |
| shadcn-vue | 最新 | shadcn/ui の Vue 移植。Reka UI（Radix Vue 後継）+ Tailwind ベース。コピー配布方式のためロックインなし |
| lucide-vue-next | 最新 | アイコンセット（lucide-react と同じデザイン体系の Vue 版）|
| tw-animate-css | 最新 | shadcn-vue が要求するアニメーションユーティリティ |

### 状態管理・通信

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| @tanstack/vue-query | 5 | サーバー状態管理。React Query の Vue 版で同じ作者・同じ設計。キャッシュ・再取得・楽観的更新を宣言的に記述 |
| fetch（標準 API） | - | Nuxt の `$fetch` または Web 標準の `fetch` を使う。Axios は採用せず軽量に保つ |

### フォーム・バリデーション

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| VeeValidate | 4 | Vue 用の宣言的フォームバリデーションライブラリ。スキーマ駆動 + Composable API |
| @vee-validate/zod | 4 | VeeValidate を zod スキーマで駆動するアダプタ |
| zod | 3 | TypeScript 型と同期するバリデーションスキーマ。@vee-validate/zod の peer 制約に合わせて 3 系を採用 |

### ドラッグ＆ドロップ

| ライブラリ | バージョン | 選定理由 |
|-----------|---------|---------|
| vue-draggable-plus | 最新 | Sortable.js ベースの Vue DnD。TypeScript 完全対応、Vue 3 / Nuxt 公式例あり、列間移動と列内並び替えを 1 ライブラリで完結 |

### コード品質

| ツール | 用途 |
|-------|------|
| ESLint | 静的解析。`@nuxt/eslint`（Nuxt 公式モジュール）を使用 |
| Prettier | コードフォーマット統一 |

### テスト

| ライブラリ | 用途 |
|-----------|------|
| Vitest | ユニットテストランナー（Vite ベースで Nuxt と相性良） |
| @nuxt/test-utils | Nuxt 環境でのコンポーネント・ページテスト |
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
| DB 名 | ローカル開発：`inquiry_tracker` / 本番：`inquiry_tracker_production`（+ cache / queue / cable の計 4 DB）|
| 接続 | ローカル：`localhost:3306` / 本番：RDS エンドポイント（`kanban-linear-db.cbq4wa46o8p3.ap-northeast-1.rds.amazonaws.com`）|
| 文字コード | `utf8mb4` / 照合順序 `utf8mb4_0900_ai_ci` |
| マイグレーション管理 | ActiveRecord Migration（`db/migrate/` に配置） |

---

## 開発環境・インフラ

| ツール | 用途 |
|-------|------|
| Docker | ローカル開発：backend / mysql の 2 コンテナ（`docker-compose.yml`）。本番：nginx + nuxt + rails の 3 コンテナ（`infra/docker-compose.prod.yml`） |
| Docker Compose v2 | ローカル開発・本番起動を一本化 |
| Amazon ECR | 本番 Docker イメージのレジストリ（backend / frontend の 2 リポジトリ）。Terraform で管理、最新 3 世代を保持 |
| Git | バージョン管理 |
| GitHub | リモートリポジトリ |
| GitHub Actions | CI（lint / test 実行） |
| Terraform | AWS リソース（VPC / EC2 / EIP / RDS / ECR / IAM / SG）すべてを IaC 化（`infra/terraform/`） |
| AWS EC2 | 本番アプリケーションサーバー（`i-0ab29376e7daed30a`）。Terraform で専用インスタンスを作成 |
| AWS SSM | SSH 不要のリモートコマンド実行。`deploy.sh` が `aws ssm send-command` 経由で EC2 を操作 |
| AWS RDS MySQL | 本番 DB（専用インスタンス `kanban-linear-db`）。DB 名 `inquiry_tracker_production` |

### Rails をコンテナ内で動かす理由

Rails の bundle install / db:prepare / rails server は **必ず `inquiry_backend` コンテナ内で実行**する（`docker compose exec backend ...`）。Windows + MySQL Shell 8.0 同梱の libmysqlclient が GSSAPI モジュール参照で破損しており、ホスト直接の `bundle exec rails ...` では `mysql2` 経由で必ず認証エラーになるため。Linux ベースのコンテナ内では同問題は発生しない。

frontend は libmysqlclient に依存しないため、ホスト側で `npm run dev` を実行する従来通りの開発フロー。

---

## ポート割当

| サービス | ローカル | 本番 |
|---------|---------|------|
| Nuxt | 3000 | コンテナ内 3000（nginx 経由） |
| Rails API | 3001 | コンテナ内 80（nginx 経由） |
| nginx | - | 8080（外部公開）|
| MySQL | 3306 | RDS エンドポイント:3306 |

ローカルでは Rails のデフォルト 3000 を 3001 に変更して Nuxt と競合を避ける。
本番は nginx がポート 8080 で受けて `/api/*` を Rails へ、それ以外を Nuxt へ転送する。

---

## バージョン整合性メモ

| 組み合わせ | 確認事項 |
|-----------|---------|
| Nuxt 4 + Vue 3 | Nuxt 4 は Vue 3.5+ を要求。Composition API の `<script setup>` を全面採用 |
| Nuxt 4 + Tailwind CSS 4 | `@nuxtjs/tailwindcss`（v3 用モジュール）は使わず、`@tailwindcss/vite` を Nuxt の vite プラグインとして直接ロードする。CSS は `app/assets/css/tailwind.css` に `@import "tailwindcss"` |
| Nuxt 4 + shadcn-vue | `shadcn-nuxt` モジュールを併用。`components.json` を手動配置し、`npx shadcn-vue@latest add <component>` でコンポーネントを追加 |
| @vee-validate/zod + zod | @vee-validate/zod は zod v3 を peer に要求。zod v4 と組み合わせると ERESOLVE エラーになるため zod 3 系を採用 |
| Rails 8.1 + Ruby 3.4 | 完全対応。Solid Queue / Cache / Cable と Kamal がデフォルト同梱 |
| Rails 8.1 + mysql2 | `mysql2` 0.5 系で動作。MySQL 8 の `caching_sha2_password` で接続できない環境（特に Windows）では、サーバー側で `mysql_native_password` をデフォルト認証に切替して回避（`docker-compose.yml` の `command` で指定済み） |
| jsonapi-serializer + ActiveRecord | `belongs_to` / `has_many` の eager_load を serializer 側で明示する |

---

## 採用しないことを明示する技術（判断の履歴）

| 技術 | 不採用理由 |
|------|----------|
| Spring Boot / Java | 既存 raisetech_kanban で採用済み。スタック差分化が目的のため除外 |
| PostgreSQL | 同上 |
| React / Next.js | 既存 raisetech_kanban が React 採用済み。本プロジェクトは Vue + Nuxt で**二刀流アピール**を狙う |
| SvelteKit / Solid / Qwik | 求人市場が React/Vue より小さく、ポートフォリオの評価軸として弱い |
| Angular | 全部入りで強力だが学習コストが高く、本プロジェクトの規模には過剰 |
| Hotwire（Turbo + Stimulus） | フロント／バック分離 + REST API という設計方針と合わない |
| Inertia.js | サーバー駆動の SPA 風。REST API 分離方針と合わない |
| Devise / 認証系 Gem | 認証なしのため不要 |
| ActionCable | リアルタイム同期は MVP 対象外 |
| Pinia（Vuex 後継） | サーバー状態は Vue Query が担当、UI ローカル状態はコンポーネント内で完結する設計のため、現時点では不要 |
| **Label / `inquiry_labels` 機能** | シングルユーザー想定で **Status × Priority の 2 軸**で「重要 × 緊急」の 4 象限を識別可能。分類用の Label は冗長と判断 |
| **assignee（担当者）機能** | シングルユーザー想定のため担当者割当が不要 |
| **5 段階優先度（Linear 準拠）** | No priority / Urgent / High / Medium / Low の 5 段階は粒度過多。**3 段階（高 / 中 / 低）+ デフォルト「低」**に簡素化することで「優先度未設定」状態を排除し、UI の null 分岐とフロント・バック双方の if 分岐を削減 |
| **優先度のカスタム CRUD（追加・編集・削除）** | 3 段階固定運用に決めたため、UI からの増減や名前・色の編集機能は不要と判断。`level` は 1..3 の UNIQUE 制約 + `inquiries.priority_id` NOT NULL + FK RESTRICT という DB 設計と整合する形で UC-09 / UC-10 / UC-11 を MVP スコープ外とする。色やラベルを変えたい場合は seed / マイグレーションで対応する |

---

## 技術選定の理由

このセクションは主要な意思決定の根拠と却下した代替案を残すための記録。後から「なぜこれを選んだのか」を辿れるようにしておく。

### 1. フロントエンド: Vue 3 + Nuxt 4

**選定の決め手**

- **既存 raisetech_kanban との差別化**: 過去作品が React 採用のため、本作で Vue を選ぶことで「React と Vue の二刀流」をポートフォリオで提示できる
- **国内求人での評価**: Vue は日本市場で React と並ぶ二大スタック。学習投資が回収しやすい
- **メタフレームワークの恩恵**: ファイルベースルーティング、SSR、TypeScript 統合、モジュール機構など、Next.js 相当の機能が標準で揃う
- **エコシステムの成熟**: shadcn-vue / vue-draggable-plus / @tanstack/vue-query などカンバンアプリに必要なライブラリが揃っている

**却下した代替案**

| 候補 | 却下理由 |
|------|---------|
| React + Next.js | 既存 raisetech_kanban で採用済み。差別化にならない |
| SvelteKit | 書き味は良いが国内求人が React/Vue より少なく、ポートフォリオの市場評価が弱い |
| Angular | 全部入りで強力だが学習コストが高く、初級編の最終課題には過剰 |
| Vue 3 + Vite（SPA のみ） | Nuxt より軽量だが、メタフレームワーク経験のアピールができない |
| Solid + SolidStart | React 風の書き味だが「React を使わない」という目的に対し JSX を書く違和感、また求人が極端に少ない |
| Qwik + QwikCity | 革新的だが DnD ライブラリが未成熟、コミュニティ小、カンバン用途に不向き |

### 2. バックエンド: Ruby on Rails 8.1（API mode）

**選定の決め手**

- **言語スタック差別化**: 既存 raisetech_kanban が Java/Spring Boot のため Ruby/Rails を選択
- **API mode の軽量さ**: View 層を持たず JSON だけ返すため、フロント分離構成と整合
- **ActiveRecord の生産性**: マイグレーション・ORM・seed が標準で揃う
- **Rails 8 の同梱機能**: Solid Queue / Cache / Cable と Kamal がデフォルトで入り、追加の gem 選定が最小化される

**却下した代替案**

| 候補 | 却下理由 |
|------|---------|
| Spring Boot / Java | 既存採用済み。差別化目的 |
| Express / NestJS | フロント（Node.js）と同言語のため学習多様性が下がる |
| Go / Echo / Gin | 学習コスト高め、Rails ほどの「速い開発体験」が得られにくい |
| FastAPI / Python | Python スタックは学習対象として有力だが、Ruby/Rails のほうが Web 向けの慣習が成熟しており、ポートフォリオ完成度を優先 |

### 3. データベース: MySQL 8

**選定の決め手**

- **既存 raisetech_kanban が PostgreSQL** のため、別 DBMS を経験する目的で MySQL を選択
- **AWS RDS の運用経験**を積みたい（Terraform で専用インスタンスを管理）
- **無料枠での運用しやすさ**

**却下した代替案**

| 候補 | 却下理由 |
|------|---------|
| PostgreSQL | 既存採用済み |
| SQLite | 単一ファイルで手軽だが、本番 RDS 想定なら MySQL/PostgreSQL のほうが学習価値が高い |
| MongoDB | リレーショナル設計（FK / JOIN）を学ぶ目的に合わない |

### 4. インフラ: Docker + AWS EC2 + RDS

**選定の決め手**

- VPC・EC2・RDS・ECR・IAM・SG をすべて Terraform で管理する**完全 IaC 構成**
- Docker により開発環境差を吸収（特に Windows の libmysqlclient 互換問題を回避）
- EC2 の初期セットアップ（Docker / git インストール・systemd 登録）は `user_data.sh.tpl` で自動化

**却下した代替案**

| 候補 | 却下理由 |
|------|---------|
| Vercel + Render / Fly.io | 楽だが AWS 操作経験が積めない |
| Heroku | 無料枠廃止後コストパフォーマンスが悪い |
| Kubernetes / EKS | 規模に対してオーバーキル |

### 5. 個別ライブラリの判断

| ライブラリ | 採用理由 | 却下した代替 |
|---|---|---|
| shadcn-vue | コピー配布でロックインなし、Linear 風 UI を最小工数で組める | Element Plus / Vuetify（重い・自由度が低い）、Naive UI（評価軸として弱い） |
| @tanstack/vue-query | サーバー状態管理のデファクト、React Query と同設計で学習資産流用可 | Pinia（サーバー状態に向かない）、Apollo Client（GraphQL 前提） |
| vue-draggable-plus | TS 完全対応の Sortable.js ラッパー、Vue 3 公式例多数 | Vue.Draggable（旧版、メンテ停滞）、Vue.Draggable.Next（TS 弱い） |
| VeeValidate + zod | スキーマ駆動でバリデーション宣言が明確、Rails 側のバリデーションと意図を揃えやすい | FormKit（独自概念多い）、手動 reactive（バリデーション再実装になる） |
| jsonapi-serializer | Rails 側で camelCase 変換と関連 includes を一元化 | active_model_serializers（メンテ停滞）、blueprinter（軽量だが Rails 8 例が少ない） |
