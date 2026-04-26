# 非機能要件

> メインドキュメント: [要件定義書](requirements.md)

## スコープ外

| 項目 | 内容 |
|------|------|
| 認証・認可 | 不要（シングルユーザー） |
| マルチユーザー | 不要 |
| 担当者マスタ | 不要（問い合わせ毎にテキストで自由入力） |
| コメント・対応履歴 | MVP 対象外（将来拡張） |
| リアルタイム同期 | MVP 対象外（Rails ActionCable 等は使用しない） |
| 検索・フィルタ・ソート UI | MVP 対象外 |
| レスポンシブ対応 | 対象外（デスクトップブラウザのみ） |

---

## UX・画面挙動

### トースト通知

#### エラー通知
- API 通信エラー（ネットワーク断・5xx 等）が発生した場合、画面右下にトースト通知を表示する
- トーストは3秒後に自動消滅する
- メッセージ例：「問い合わせの保存に失敗しました」
- 左ボーダーは赤（`#f87462`）

#### 成功通知
- 以下の操作が完了したとき、同じく画面右下にトーストを表示する
  - 問い合わせ作成：「問い合わせを作成しました」
  - 問い合わせ保存：「問い合わせを保存しました」
  - 問い合わせ削除：「問い合わせを削除しました」
  - ステータス作成：「ステータス「{名前}」を作成しました」
  - ステータス削除：「ステータスを削除しました」
  - 優先度作成／削除：同様
  - ラベル作成：「ラベル「{名前}」を作成しました」
  - ラベル削除：「ラベルを削除しました」
- トーストは3秒後に自動消滅する
- 左ボーダーは緑（`#4bce97`）

### ローディング表示
- 初期データ取得中（`GET /api/inquiries`）はスケルトン表示（骨格 UI）を行う
- 個別操作（問い合わせ作成・移動等）中は対象要素を disabled にする（二重送信防止）

### InquiryModal の開閉
- 以下の3操作すべてでモーダルを閉じることができる
  - ×ボタンのクリック
  - オーバーレイ（背景）のクリック
  - Esc キー
- 未保存の変更がある場合は、閉じる前に確認ダイアログを表示する

### 優先度バッジの表示ルール
| レベル | 表示名 | 色 |
|-------|--------|-----|
| 1 | 高 | 赤（`#E74C3C`） |
| 2 | 中 | 黄（`#F1C40F`） |
| 3 | 低 | 青（`#3498DB`） |

- 優先度は 3 段階固定（level 1〜3）。名前・色の UI 編集は MVP スコープ外
- フロントエンドでは漢字 1 文字（高 / 中 / 低）+ priority.color の薄い背景でバッジ表示する

### テキスト省略ルール
- カードサムネイル上のタイトルは1行表示・超過分は `...` で省略
- InquiryModal 内では全文を表示する

---

## 性能・制限

| 項目 | 制限値 | 挙動 |
|------|--------|------|
| ステータス数の上限 | 20件 | 20件到達時、ステータス追加ボタンを非表示にする |
| 優先度数の上限 | 10件 | 設定画面で追加ボタンを非活性にする |
| ラベル数の上限 | 50件 | 設定画面で追加ボタンを非活性にする |
| 問い合わせ数の上限 | ステータスあたり500件 | 500件到達時、対応するステータス列の「＋」ボタンを非表示にする |
| 通常操作のレスポンスタイム | 500ms 以内 | CRUD 操作（作成・更新・削除・移動） |
| 初期表示のレスポンスタイム | 1秒以内 | `GET /api/inquiries` のレスポンス取得〜画面描画完了まで |

---

## 環境・ブラウザ

### 対応ブラウザ
| ブラウザ | バージョン |
|---------|---------|
| Google Chrome | 最新版 |
| Microsoft Edge | 最新版 |
| Mozilla Firefox | 最新版 |

### 動作 OS
- Windows・macOS・Linux すべて対応（ローカル開発）
- 本番は AWS EC2（Amazon Linux 2023 想定）

### 必要な実行環境

| 項目 | バージョン |
|------|---------|
| Node.js | v20 LTS 以上 |
| Ruby | 3.3 以上 |
| MySQL | 8.0 以上 |
| Docker | 最新安定版 |
| Docker Compose | v2 以上 |

---

## セキュリティ

| 項目 | 対応内容 |
|------|---------|
| XSS 対策 | React の JSX／Next.js による自動エスケープを利用。`dangerouslySetInnerHTML` は使用禁止 |
| SQL インジェクション対策 | ActiveRecord のパラメータバインディングのみ使用。`find_by_sql` 等で生 SQL に外部入力を連結しない |
| マスアサインメント対策 | Rails の Strong Parameters を利用し、許可する属性を明示する |
| CORS | 開発：`http://localhost:3000`（Next.js dev）のみ許可。本番：EC2 のフロント配信オリジンのみ許可 |
| 環境変数 | DB 接続情報（DB_HOST / DB_USERNAME / DB_PASSWORD 等）は `.env` で管理し Git 管理外とする |

---

## インフラ・運用

| 項目 | 内容 |
|------|------|
| デプロイ先 | AWS EC2（`i-0ab29376e7daed30a`、13.193.154.150）+ RDS MySQL（専用インスタンス） |
| 本番 DB 名 | `inquiry_tracker_production`（Rails 8.1 の複数 DB 構成: primary / cache / queue / cable の 4 DB） |
| 本番コンテナ構成 | **3 コンテナ**（nginx + nuxt + rails）を `infra/docker-compose.prod.yml` で管理。ポート 8080 で公開 |
| nginx | リバースプロキシ。`/api/*` → rails コンテナ（:80）、`/` → nuxt コンテナ（:3000） |
| コンテナレジストリ | Amazon ECR（`kanban-linear-backend` / `kanban-linear-frontend`）。最新 3 世代を保持 |
| IaC | Terraform（`infra/terraform/`）で VPC / EC2 / EIP / RDS / ECR / IAM / SG すべてを管理 |
| デプロイ方法 | `deploy.sh`（SSH 不要）: ローカルでイメージをビルド → ECR push → SSM Send-Command で EC2 に ECR pull + `docker compose up -d` |
| EC2 初回セットアップ | `user_data.sh.tpl`（Terraform が `terraform apply` 時に EC2 へ投入）: Docker + git + Compose v2 plugin インストール + systemd サービス（`kanban-linear.service`）登録 |
| ログ | Rails：標準ログ出力（STDOUT → docker logs）。CloudWatch Logs への転送は本番で検討 |

---

## API エラーレスポンス形式

すべての API エラーは以下の統一フォーマットで返す。

```json
{
  "error": "ERROR_CODE",
  "message": "ユーザー向けエラーメッセージ",
  "details": { "field": "title", "reason": "blank" }
}
```

| HTTP ステータス | error コード | 用途 |
|-------------|------------|------|
| 400 | `BAD_REQUEST` | バリデーションエラー（タイトル空文字・文字数超過等） |
| 404 | `NOT_FOUND` | 指定 ID のリソースが存在しない |
| 409 | `CONFLICT` | ステータス削除時の移動先未指定など、前提条件違反 |
| 422 | `UNPROCESSABLE_ENTITY` | Rails の validation エラー（`details` に field 情報を含める） |
| 500 | `INTERNAL_SERVER_ERROR` | 予期しないサーバーエラー |
