# API設計

> メインドキュメント: [要件定義書](requirements.md)

ベースURL:

| 環境 | URL |
|------|-----|
| ローカル開発 | `http://localhost:3001/api` （Rails が 3001、Next.js が 3000） |
| 本番 | `https://<EC2 ドメイン>/api` |

※ Next.js（3000）と Rails（3001）のポート衝突を避けるため、Rails 側のデフォルトを 3001 に変更する運用とする。

---

## エンドポイント一覧

### 問い合わせ（inquiries）

| Method | Path | 説明 | Request Body | Response |
|--------|------|------|-------------|---------|
| GET | /inquiries | 全問い合わせ取得（ステータス・優先度・ラベル含む） | - | `Inquiry[]` |
| GET | /inquiries/:id | 問い合わせ1件取得 | - | `Inquiry` |
| POST | /inquiries | 問い合わせ作成 | `{ statusId, priorityId?, title, description?, category?, assignee?, labelIds? }` | `Inquiry` |
| PATCH | /inquiries/:id | 問い合わせ更新 | `{ statusId?, priorityId?, title?, description?, category?, assignee? }` | `Inquiry` |
| DELETE | /inquiries/:id | 問い合わせ削除 | - | 204 |
| PATCH | /inquiries/:id/move | 問い合わせ移動（DnD） | `{ statusId, position }` | `Inquiry` |

### ステータス（statuses）

| Method | Path | 説明 | Request Body | Response |
|--------|------|------|-------------|---------|
| GET | /statuses | ステータス一覧取得（表示順） | - | `Status[]` |
| POST | /statuses | ステータス作成 | `{ name, color }` | `Status` |
| PATCH | /statuses/:id | ステータス更新（名前・色） | `{ name?, color? }` | `Status` |
| PATCH | /statuses/:id/move | ステータス列の並び替え | `{ position }` | `Status` |
| DELETE | /statuses/:id | ステータス削除（所属問い合わせの移動先指定） | クエリ `?move_to={id}`（該当ステータスに問い合わせが存在する場合は必須） | 204 |

### 優先度（priorities）

| Method | Path | 説明 | Request Body | Response |
|--------|------|------|-------------|---------|
| GET | /priorities | 優先度一覧取得（表示順） | - | `Priority[]` |
| POST | /priorities | 優先度作成 | `{ name, level, color }` | `Priority` |
| PATCH | /priorities/:id | 優先度更新 | `{ name?, level?, color? }` | `Priority` |
| PATCH | /priorities/:id/move | 表示順の並び替え | `{ position }` | `Priority` |
| DELETE | /priorities/:id | 優先度削除（所属問い合わせの priority は NULL に） | - | 204 |

### ラベル（labels）

| Method | Path | 説明 | Request Body | Response |
|--------|------|------|-------------|---------|
| GET | /labels | ラベル一覧取得 | - | `Label[]` |
| POST | /labels | ラベル作成 | `{ name, color }` | `Label` |
| PATCH | /labels/:id | ラベル更新 | `{ name?, color? }` | `Label` |
| DELETE | /labels/:id | ラベル削除 | - | 204 |
| POST | /inquiries/:id/labels/:labelId | 問い合わせにラベル追加 | - | 200 |
| DELETE | /inquiries/:id/labels/:labelId | 問い合わせからラベル解除 | - | 204 |

---

## レスポンス型（TypeScript 表現）

```typescript
type Status = {
  id: number;
  name: string;
  color: string;       // HEX: "#F2C94C"
  position: number;
};

type Priority = {
  id: number;
  name: string;
  level: 0 | 1 | 2 | 3 | 4;
  color: string;
  position: number;
};

type Label = {
  id: number;
  name: string;
  color: string;
};

type Inquiry = {
  id: number;
  statusId: number;
  status: Status;              // eager load
  priorityId: number | null;
  priority: Priority | null;   // eager load
  title: string;
  description: string | null;
  category: string | null;
  assignee: string | null;
  position: number;
  labels: Label[];             // eager load
  createdAt: string;           // ISO 8601: "2026-05-01T12:34:56Z"
  updatedAt: string;
};
```

**JSON 命名規則**
- Rails 側は `jsonapi-serializer` または `ActiveModelSerializers` を用い、キーは **camelCase** で返す（Next.js 側との親和性）。

---

## リクエスト例

### 問い合わせ作成

```http
POST /api/inquiries
Content-Type: application/json

{
  "statusId": 1,
  "priorityId": 2,
  "title": "ログインできない",
  "description": "パスワードリセット後にログイン不可",
  "category": "認証",
  "assignee": "山田",
  "labelIds": [3, 5]
}
```

### 問い合わせ移動（DnD）

```http
PATCH /api/inquiries/42/move
Content-Type: application/json

{
  "statusId": 3,
  "position": 2
}
```

---

## エラーレスポンス形式

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
| 400 | `BAD_REQUEST` | リクエスト構文エラー・必須パラメータ不足 |
| 404 | `NOT_FOUND` | 指定 ID のリソースが存在しない |
| 409 | `CONFLICT` | ステータス削除時の移動先未指定・最後の1件削除など、前提条件違反 |
| 422 | `UNPROCESSABLE_ENTITY` | Rails の validation エラー（`details` に field 情報を含める） |
| 500 | `INTERNAL_SERVER_ERROR` | 予期しないサーバーエラー |

**422 の例**

```json
{
  "error": "UNPROCESSABLE_ENTITY",
  "message": "入力内容に誤りがあります",
  "details": [
    { "field": "title", "reason": "blank" },
    { "field": "color", "reason": "invalid_format" }
  ]
}
```

---

## CORS 設定方針

Rails の `rack-cors` で以下を許可：
- 開発：`http://localhost:3000`
- 本番：EC2 のフロント配信オリジン

メソッド：`GET POST PATCH DELETE OPTIONS`
ヘッダー：`Content-Type Authorization`（Authorization は将来拡張用）
