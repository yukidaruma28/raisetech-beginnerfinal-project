# raisetech-beginner-final（仮）

Linear 風の問い合わせ管理アプリ。RaiseTech 初級編 最終課題としてのポートフォリオ作品。

- **スタック**: Ruby on Rails 7.1（API mode）/ Next.js 15（App Router）/ MySQL 8
- **要件・設計**: [docs/requirements.md](docs/requirements.md) を起点にすべての設計ドキュメントを参照
- **開発者向けガイド**: [CLAUDE.md](CLAUDE.md)（Claude Code が自動で読む。人間も参照可）

---

## Quick Start（新規マシンで一からセットアップする）

以下の手順を上から順に実行すれば、空のリポジトリから開発可能な状態まで再現できる。

### 1. GitHub リポジトリとして登録する

このディレクトリ（`newapp/`）をそのまま git リポジトリ化して GitHub にプッシュする。

```bash
# このディレクトリのルートで実行
cd path/to/newapp

# git 初期化
git init -b main

# main への直接プッシュを拒否する pre-push フックを有効化
git config core.hooksPath .githooks
chmod +x .githooks/pre-push

# 初期コミット
git add .
git commit -m "chore: initial project scaffold with Claude Code config"

# GitHub 上に private リポジトリを作成して push（gh CLI 使用）
gh repo create raisetech-beginner-final --private --source=. --remote=origin --push

# （リポジトリ名は任意。public にする場合は --public に変更）
```

gh CLI が未設定なら `gh auth login` を先に済ませる。

### 2. Docker で MySQL を起動する

```bash
docker-compose up -d
# → MySQL が localhost:3306 で起動
```

`docker-compose.yml` が未作成の場合は、以下を `newapp/docker-compose.yml` として置く：

```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: inquiry_mysql
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: inquiry_tracker
      MYSQL_USER: inquiry
      MYSQL_PASSWORD: inquirypass
    volumes:
      - mysql_data:/var/lib/mysql
    command: --default-authentication-plugin=caching_sha2_password

volumes:
  mysql_data:
```

### 3. バックエンド（Rails API）を scaffold する

```bash
# プロジェクトルートで
rails new backend --api --database=mysql --skip-test

cd backend

# Gemfile に追加（末尾にまとめて追記）
bundle add jsonapi-serializer rack-cors
bundle add rspec-rails factory_bot_rails --group development,test
bundle add dotenv-rails --group development,test

# RSpec 初期化
bundle exec rails generate rspec:install

# DB 接続を docker-compose.yml に合わせる
# config/database.yml の default: を以下に差し替える（例）
#
#   default: &default
#     adapter: mysql2
#     encoding: utf8mb4
#     username: inquiry
#     password: inquirypass
#     host: 127.0.0.1
#     port: 3306

bundle exec rails db:create db:migrate

# 起動確認（ポート 3001）
bundle exec rails server -p 3001
# → http://localhost:3001
```

### 4. フロントエンド（Next.js）を scaffold する

```bash
# プロジェクトルートに戻って
cd ..

npx create-next-app@latest frontend \
  --typescript --tailwind --app --eslint \
  --src-dir=false --import-alias="@/*" \
  --use-npm

cd frontend

# 依存ライブラリ追加
npm install @tanstack/react-query @dnd-kit/core @dnd-kit/sortable \
            react-hook-form zod lucide-react

# shadcn/ui 初期化（対話式に進める）
npx shadcn@latest init

# 起動確認（ポート 3000）
npm run dev
# → http://localhost:3000
```

### 5. 日常の開発フロー

- 新機能に着手するときは Claude Code で `/go {機能説明}` と入力する
  → Plan モードで実装計画作成 → GitHub Issue 作成 → ブランチ作成 → 実装 → PR まで自動化される
- 詳細な規約は [CLAUDE.md](CLAUDE.md) の「開発フロー」セクション

---

## ドキュメント

| ファイル | 内容 |
|---------|------|
| [docs/requirements.md](docs/requirements.md) | 要件定義（トップ。他ドキュメントへの索引を含む） |
| [docs/use-cases.md](docs/use-cases.md) | ユースケース UC-01〜15 |
| [docs/non-functional.md](docs/non-functional.md) | 非機能要件 |
| [docs/data-design.md](docs/data-design.md) | ER 図・テーブル定義・position 管理ルール |
| [docs/api-design.md](docs/api-design.md) | REST API 仕様 |
| [docs/screen-design.md](docs/screen-design.md) | 画面レイアウト・インタラクション |
| [docs/tech-stack.md](docs/tech-stack.md) | 採用ライブラリとバージョン整合性 |
| [docs/setup-notes.md](docs/setup-notes.md) | 本テンプレートの由来・差分サマリ（raisetech_kanban 比較） |

---

## 前提ツール

| ツール | バージョン | インストール例 |
|-------|---------|--------------|
| Git | 最新 | 省略 |
| GitHub CLI (`gh`) | 最新 | `winget install GitHub.cli` |
| Docker Desktop | 最新 | 省略 |
| Ruby | 3.3 以上 | `winget install RubyInstallerTeam.RubyWithDevKit.3.3` |
| Node.js | 20 LTS 以上 | `winget install OpenJS.NodeJS.LTS` |

---

## デプロイ

AWS EC2 + RDS MySQL（既存 raisetech_kanban インスタンスと同居運用）。詳細は `docs/non-functional.md` の「インフラ・運用」を参照。Terraform 構成は別途追加予定。
