# templates（新リポジトリ初期化用 設定ファイル一式）

本ディレクトリは **現 raisetech_kanban リポジトリの Claude Code 関連設定・開発フロー設定を、新アプリ用（Rails + Next.js + MySQL）に書き換えたもの**。新リポジトリを作成した直後に、これらを **リポジトリルート直下にコピー** することで、同じ Issue ルール／ブランチ命名／CI チェック／Claude スキルを適用できる。

## 配置マッピング

| 本ディレクトリ内 | コピー先（新リポジトリのルート） |
|------------------|-------------------------------|
| `CLAUDE.md` | `/CLAUDE.md` |
| `.gitignore` | `/.gitignore` |
| `.claude/settings.json` | `/.claude/settings.json` |
| `.claude/agents/go.md` | `/.claude/agents/go.md` |
| `.githooks/pre-push` | `/.githooks/pre-push` |
| `.github/pull_request_template.md` | `/.github/pull_request_template.md` |
| `.github/ISSUE_TEMPLATE/*.yml` | `/.github/ISSUE_TEMPLATE/` |
| `.github/workflows/*.yml` | `/.github/workflows/` |

## 適用手順（新リポジトリ作成直後に1回だけ実行）

```bash
# 新リポジトリをクローンした直後、そのルートで：

# 1. 本ディレクトリをコピー元として使う（パスは適宜調整）
SRC="/c/Users/yukio/OneDrive/デスクトップ/raiseTech_AI/docs/newapp/templates"

cp "$SRC/CLAUDE.md"      ./CLAUDE.md
cp "$SRC/.gitignore"     ./.gitignore

mkdir -p .claude/agents .githooks .github/ISSUE_TEMPLATE .github/workflows
cp "$SRC/.claude/settings.json"              .claude/settings.json
cp "$SRC/.claude/agents/go.md"               .claude/agents/go.md
cp "$SRC/.githooks/pre-push"                 .githooks/pre-push
cp "$SRC/.github/pull_request_template.md"   .github/pull_request_template.md
cp "$SRC/.github/ISSUE_TEMPLATE/"*.yml       .github/ISSUE_TEMPLATE/
cp "$SRC/.github/workflows/"*.yml            .github/workflows/

# 2. pre-push フックに実行権限
chmod +x .githooks/pre-push

# 3. git フックパスを設定（main への直接 push を拒否）
git config core.hooksPath .githooks

# 4. 初期コミット
git add .
git commit -m "chore: initial project scaffold with Claude Code config"
```

## 注意

- `.claude/settings.local.json` と `.claude/scheduled_tasks.lock` はコピー対象外（ローカル用・自動生成のため `.gitignore` に含めてある）
- `.github/workflows/` には CI（backend / frontend テスト）用のワークフローは含まれていない。Rails / Next.js 用の CI は新リポジトリで別途追加する
- 本テンプレートは **現 raisetech_kanban の構成を新スタック向けに書き換え済み**。Spring Boot / Maven / PostgreSQL への言及はすべて Rails / bundler / MySQL に置き換えてある

## 差分サマリ（現 raisetech_kanban からの変更点）

| ファイル | 主な変更 |
|---------|---------|
| `CLAUDE.md` | 起動コマンド・アーキテクチャ・ポート・API パスを Rails + Next.js + MySQL 版に刷新 |
| `.claude/settings.json` | `mvn`/`mvnw`/`java`/`psql` を削除、`bundle`/`rails`/`mysql` を追加 |
| `.claude/agents/go.md` | Step 5 動作確認の起動コマンドを Rails / Next.js に差し替え |
| `.github/pull_request_template.md` | 動作確認項目の文言を汎用化 |
| `.github/ISSUE_TEMPLATE/bug_report.yml` | 環境情報の起動方法欄を新アプリ向けに |
| ワークフロー 3本 | そのまま再利用（リポジトリ非依存） |
