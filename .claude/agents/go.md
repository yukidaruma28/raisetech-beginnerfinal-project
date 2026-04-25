---
name: go
description: 新機能の計画・Issue作成・ブランチ作成・実装を一連のフローで行う。引数に機能の説明を渡す。例: /go 問い合わせ編集機能の実装
---

## 役割

新機能の着手フローを標準化するスキル。**Plan モード → Issue作成 → ブランチ作成 → 実装** の順序を必ず守る。実装は Issue とブランチが揃ってから開始する。

## ステップ

### Step 1: コードベース探索

Explore サブエージェントを起動し、実装に関係するファイル・既存パターンを調査する。

### Step 2: Plan モードで実装プランを作成

`EnterPlanMode` を呼び出し、以下の形式でプランファイルに記載する。

```
## 概要
（1〜2文）

## バックエンド
- 新規エンドポイント・変更点

## フロントエンド
- 変更するコンポーネント・API呼び出し

## 完了条件
- [ ] 項目1
- [ ] 項目2
...（5〜8項目）

## 変更予定ファイル
- backend/app/controllers/api/xxx_controller.rb
- frontend/components/xxx.tsx
```

記載後、`ExitPlanMode` を呼び出してユーザーの承認を待つ。

### Step 3: GitHub Issue 作成

承認後、以下を実行する。Issue 本文の完了条件は Step 2 のプランと同じ内容にする。

```bash
gh issue create \
  --title "{機能タイトル}" \
  --body "## 概要
{概要}

## 完了条件
- [ ] 項目1
- [ ] 項目2
..."
```

出力された Issue URL から番号（例: `#21`）を取得する。

### Step 4: ブランチ作成

CLAUDE.md のブランチ命名規則に従う。必ず main を最新化してからブランチを切る。

```bash
git checkout main
git pull origin main
git checkout -b feature/{issue番号}-{slug}
```

- slug は機能を端的に表す英数字・ハイフンのみ、20文字以内
- 例: `feature/21-edit-inquiry`

完了後、以下のチェックリストを表示する：

```
✅ Issue #{番号} 作成済み — {URL}
✅ main を pull 済み
✅ ブランチ feature/{番号}-{slug} 作成済み
実装を開始します。
```

### Step 5: 実装

Step 2 のプランに従って実装を進める。

### Step 6: PR 作成

実装完了後、以下のフォーマットで PR を作成する。

**タイトル形式：**
```
feat: {機能名}-#{Issue番号}
fix: {修正内容}-#{Issue番号}
chore: {変更内容}-#{Issue番号}
docs: {変更内容}-#{Issue番号}
```

**本文：** PR テンプレートに従い、冒頭の関連 Issue 欄に必ず両方を記載する。

```
issue #{Issue番号}
Closes #{Issue番号}
```

PR 作成後、以下の手順で動作確認とチェックボックスの記入を行う。

**動作確認手順：**

1. MySQL コンテナを起動する（`docker-compose up -d`）
2. バックエンドを起動する（`cd backend && bundle exec rails server -p 3001`）
3. フロントエンドを起動する（`cd frontend && npm run dev`）
4. 実装した機能を実際に操作して動作を確認する
5. 既存機能が壊れていないことを確認する

**チェックボックスを更新する：**

確認できた項目を `- [ ]` から `- [x]` に書き換えて PR 本文を更新する。

```bash
gh pr edit {PR番号} --body "$(cat <<'EOF'
## 関連 Issue

issue #{Issue番号}
Closes #{Issue番号}

---

## 動作確認

- [x] バックエンドが正常に起動する
- [x] フロントエンドが正常に起動する
- [x] 変更した機能が期待通り動作する
- [x] 既存の機能が壊れていないことを確認した

（以下、Test plan のチェックボックスも同様に更新）
EOF
)"
```

すべてのチェックボックスが `[x]` になったことを確認してからマージする。
