# 視聴管理アプリ

![Backend CI](https://github.com/yukidaruma28/raisetech-beginnerfinal-project/actions/workflows/backend-ci.yml/badge.svg) ![Frontend CI](https://github.com/yukidaruma28/raisetech-beginnerfinal-project/actions/workflows/frontend-ci.yml/badge.svg)

Linear 風の UI でアニメ・映画の視聴進捗をステータス別グループリストで管理する、シングルユーザー向けの個人用アプリ。RaiseTech 初級編 最終課題のポートフォリオ作品。

- **🌐 本番デモ**: http://13.193.154.150:8080/
- **特徴**: シングルユーザー / 認証なし / 1 ボード固定 / DnD で並び替え
- **スタック**: Rails 8.1（API mode）/ Nuxt 4（Vue 3）/ MySQL 8 / AWS EC2 + RDS / Terraform / Docker

<img width="1920" height="957" alt="視聴管理アプリのスクリーンショット" src="https://github.com/user-attachments/assets/b4e2b939-41a0-4be8-9736-c98974c1c701" />

[▶ 説明動画を見る](https://youtu.be/tQxZqqJAMuI)

---

## できること

### 作品（カード）
- 一覧をステータス別グループリストで表示（ステータス列にグループ化）
- 新規作成（タイトル・説明・ステータス・優先度を指定）
- タイトル・説明・ステータス・優先度を編集（カードクリックでモーダル → 各フィールドをインライン編集・自動保存）
- 削除
- 列内・列間を ドラッグアンドドロップ で並び替え

### ステータス列
- 一覧表示（position 順）
- 新規作成（名前・色を指定）
- 名前・色を編集（ヘッダークリックでインライン入力 → フォーカスアウトで自動保存）
- 削除（所属作品がある場合は移動先ステータスを指定して付け替えてから削除）
- ドラッグアンドドロップ で列順を並び替え

### 優先度
- 高 / 中 / 低 の 3 段階固定（追加・編集・削除は UI 非提供）

---

## 要件・画面設計

| ドキュメント | 内容 |
|------------|------|
| [要件定義](docs/requirements.md) | 機能要件・用語定義・ユースケース索引 |
| [画面設計](docs/screen-design.md) | 画面レイアウト・インタラクション仕様 |
| [API設計](docs/api-design.md) | REST API エンドポイント・レスポンス型 |

---

## 技術スタック

### フロントエンド
- Nuxt 4（Vue 3 / TypeScript）
- Tailwind CSS 4
- shadcn-vue（UI コンポーネント）
- @tanstack/vue-query（サーバー状態管理）
- vue-draggable-plus（DnD）
- VeeValidate + zod（フォームバリデーション）
- ESLint / Prettier

### バックエンド
- Ruby 3.4 / Rails 8.1（API mode）
- jsonapi-serializer（camelCase JSON 出力）
- rack-cors
- RSpec / RuboCop / Brakeman

### データベース
- MySQL 8（ローカル: Docker、本番: AWS RDS）

### インフラ
- Docker / Docker Compose v2
- AWS EC2（Amazon Linux 2023）/ AWS RDS MySQL
- Amazon ECR（Docker イメージレジストリ）
- AWS SSM（SSH 不要のリモート操作）
- Terraform（VPC / EC2 / EIP / RDS / ECR / IAM / SG を IaC 管理）
- nginx（リバースプロキシ、ポート 8080）
- GitHub Actions（CI: lint / test / PR チェック）

### 開発ツール
- Node.js 22 LTS / npm
- Vite 7（Nuxt 内部ビルドツール）
- GitHub CLI（Issue / PR 自動化）

---

## アーキテクチャ

```
ローカル開発:
  [host]   npm run dev (Nuxt :3000)
              ↓ HTTP
  [docker] backend (Rails :3001) ─→ mysql (:3306)

本番 (EC2 + RDS):
  Internet → :8080 [nginx] ─┬─ /api/* → backend (Rails :80)
                            └─ /*     → nuxt    (Nuxt :3000)
                                            ↓
                                        RDS MySQL
```

ローカルは backend と DB を Docker で動かし、Nuxt はホスト側で `npm run dev`。本番は nginx を front に置いた 3 コンテナ構成で、ECR の latest タグを SSM 経由で pull する。

---

## Quick Start

### 前提ツール

| ツール | バージョン | 用途 |
|------|---------|------|
| Docker Desktop | 最新 | バックエンド + MySQL |
| Node.js | 22 LTS 以上 | Nuxt 開発サーバー |
| Git | 最新 | バージョン管理 |
| GitHub CLI (`gh`) | 任意 | Issue / PR 自動化 |

### 起動手順

```bash
# 1. clone
git clone https://github.com/yukidaruma28/raisetech-beginnerfinal-project.git
cd raisetech-beginnerfinal-project

# 2. バックエンド (MySQL + Rails) を起動
docker compose up -d
# → MySQL: localhost:3306, Rails API: localhost:3001
# 初回は backend コンテナ内で bundle install + db:prepare が走るので数分かかる

# 3. フロントエンドを起動
cd frontend
npm install
npm run dev
# → http://localhost:3000
```

ブラウザで http://localhost:3000 を開いてリストビューが表示されれば成功。

---

## よく使うコマンド

### Rails（必ずコンテナ越しに発行）

Windows 環境の libmysqlclient 互換問題を避けるため、Rails コマンドはホストではなく `backend` コンテナ内で実行する。

```bash
docker compose exec backend bundle exec rails console
docker compose exec backend bundle exec rails db:migrate
docker compose exec backend bundle exec rspec
```

### 環境のリセット / トラブル対処

```bash
docker compose down -v   # DB データも含めて完全リセット
npx kill-port 3000       # フロントのポートを解放
npx kill-port 3001       # バックエンドのポートを解放
```

### PR 前の Lint / 型チェック（CI と同じ）

```bash
# Backend（docker compose 起動済み前提）
docker compose exec backend bundle exec rspec
docker compose exec backend bundle exec rubocop
docker compose exec backend bundle exec brakeman --no-pager --quiet

# Frontend
cd frontend
npm run lint
npx nuxi typecheck
```

---

## このプロジェクト独自の設定

RaiseTech カリキュラムの標準構成ではなく、このプロジェクト固有の運用ルール。

### Git フック（main 直 push 防止）

```bash
git config core.hooksPath .githooks
```

### 開発フロー

- Claude Code で `/go {機能説明}` を実行すると、Plan 作成 → Issue 作成 → ブランチ作成 → 実装 → PR まで自動化される
- ブランチ命名: `feature/{番号}-{slug}` / `fix/...` / `chore/...` / `docs/...`
- PR タイトル: `feat: {機能名}-#{Issue番号}`（例: `feat: ステータス編集-#48`）
- PR 本文の冒頭に `Closes #N` を記載（マージ時に Issue 自動クローズ）
- 詳細な規約は [CLAUDE.md](CLAUDE.md) の「開発フロー」セクション

### CI ワークフロー

PR を作成すると以下が自動で走り、すべて green でないとマージできない。

| ワークフロー | トリガー | 内容 |
|-------------|---------|------|
| `backend-ci.yml` | `backend/**` 変更 | RSpec / RuboCop / Brakeman |
| `frontend-ci.yml` | `frontend/**` 変更 | ESLint / `nuxi typecheck` |
| `check-branch-name.yml` | 全 PR | ブランチ名規則チェック |
| `check-checkboxes.yml` | 全 PR | PR / Issue のチェックボックス完了確認 |
| `check-issue-link.yml` | 全 PR | `Closes #N` 等の Issue 参照確認 |

---

## 本番デプロイ

### 構成

- **EC2**: Terraform 管理の専用インスタンス（Amazon Linux 2023・参照なし）
- **RDS**: 専用 MySQL インスタンス
- **ECR**: `kanban-linear-backend` / `kanban-linear-frontend` の 2 リポジトリ（最新 3 世代を保持）
- **コンテナ**: nginx (8080) + nuxt (3000) + rails (80) を `infra/docker-compose.prod.yml` で管理
- **systemd**: `kanban-linear.service` で OS 起動時に自動起動
- **デプロイ方式**: SSH 不要。`deploy.sh` が AWS SSM Send-Command で EC2 にコマンドを発行する

---

## ドキュメント

| ファイル | 内容 |
|---------|------|
| [docs/requirements.md](docs/requirements.md) | 要件定義（トップ。他ドキュメントへの索引） |
| [docs/use-cases.md](docs/use-cases.md) | ユースケース UC-01〜15 |
| [docs/non-functional.md](docs/non-functional.md) | 非機能要件・インフラ運用 |
| [docs/data-design.md](docs/data-design.md) | ER 図・テーブル定義・position 管理 |
| [docs/api-design.md](docs/api-design.md) | REST API 仕様 |
| [docs/screen-design.md](docs/screen-design.md) | 画面レイアウト・インタラクション |
| [docs/tech-stack.md](docs/tech-stack.md) | 採用ライブラリ・バージョン整合性 |
| [docs/setup-notes.md](docs/setup-notes.md) | テンプレートの由来・差分サマリ |
| [CLAUDE.md](CLAUDE.md) | Claude Code 用開発ガイド（人間も参照可） |
