# API設計

> メインドキュメント: [要件定義書](requirements.md)

ベースURL:

| 環境 | URL |
|------|-----|
| ローカル開発 | `http://localhost:3001/api` （Rails が 3001、Nuxt が 3000） |
| 本番 | `https://<EC2 ドメイン>/api` |

※ Nuxt（3000）と Rails（3001）のポート衝突を避けるため、Rails 側のデフォルトを 3001 に変更する運用とする。

## 実装状況（2026-04-26 時点）

| エンドポイント | 状態 |
|---|---|
| `GET /api/statuses` | ✅ 実装済み |
| `GET /api/priorities` | ✅ 実装済み |
| `GET /api/inquiries` | ✅ 実装済み（`priorityId` 含む、read-only）|
| `POST /api/inquiries` | ✅ 実装済み（UC-02、`priorityId` 省略時「低」自動割当・`position` 自動採番）|
| `PATCH /api/inquiries/:id` | ✅ 実装済み（UC-03、部分更新・camelCase/snake_case 双方対応・`position` は据え置き）|
| `DELETE /api/inquiries/:id` | ✅ 実装済み（UC-04、204 No Content・物理削除）|
| `PATCH /api/inquiries/:id/move` | ⏳ 未実装（UC-05 で実装予定）|
| `/api/statuses` の `POST` / `PATCH` / `DELETE` | ⏳ 未実装（UC-06〜08 で実装予定）|
| `/api/priorities` の `POST` / `PATCH` / `DELETE` | ❌ **MVP スコープ外**（3 段階固定運用、`docs/tech-stack.md` 参照）|
| `/api/labels` 系 | ❌ MVP スコープ外（`docs/tech-stack.md` 参照）|
| Inquiry の `assignee` / `category` / `labels` | ❌ MVP スコープ外 |

---

## エンドポイント一覧

### 問い合わせ（inquiries）

MVP スコープでは `assignee` / `category` / `labels` フィールドを取り扱わない。

| Method | Path | 説明 | Request Body | Response |
|--------|------|------|-------------|---------|
| GET | /inquiries | 全問い合わせ取得（ステータス・優先度を eager load） | - | `Inquiry[]` |
| GET | /inquiries/:id | 問い合わせ1件取得 | - | `Inquiry` |
| POST | /inquiries | 問い合わせ作成（`priorityId` 省略時は「低」(level 3) をデフォルト、`position` は同 status 内 MAX+1 を自動採番） | `{ statusId, priorityId?, title, description? }` | 201 + `Inquiry` |
| PATCH | /inquiries/:id | 問い合わせ部分更新（送信されたフィールドのみ更新。`position` は status_id 変更時も据え置き、UC-05 で再採番予定） | `{ statusId?, priorityId?, title?, description? }` | 200 + `Inquiry` |
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

**3 段階固定運用（高 / 中 / 低）+ デフォルト「低」**。`level` は 1..3 の UNIQUE 制約で常に 3 件。`inquiries.priority_id` は NOT NULL（FK は RESTRICT）で必ず Inquiry にひもづく前提。

MVP では **`POST` / `PATCH` / `DELETE` を提供しない**（追加・編集・削除は不要、`docs/tech-stack.md` の「採用しないことを明示する技術」参照）。一覧取得のみが UI から呼ばれる。

| Method | Path | 説明 | Request Body | Response |
|--------|------|------|-------------|---------|
| GET | /priorities | 優先度一覧取得（表示順、常に 3 件） | - | `Priority[]` |
| ~~POST~~ | ~~/priorities~~ | ❌ MVP スコープ外（3 段階固定） | - | - |
| ~~PATCH~~ | ~~/priorities/:id~~ | ❌ MVP スコープ外（3 段階固定） | - | - |
| ~~PATCH~~ | ~~/priorities/:id/move~~ | ❌ MVP スコープ外 | - | - |
| ~~DELETE~~ | ~~/priorities/:id~~ | ❌ MVP スコープ外（3 段階固定） | - | - |

### ラベル（labels）

**❌ MVP スコープ外**。シングルユーザー想定で Status × Priority の 2 軸により識別可能なため、Label 機能は実装しない方針（`docs/tech-stack.md` の「採用しないことを明示する技術」参照）。`labels` テーブル定義は `docs/data-design.md` に残しているが、エンドポイント・モデル・UI のいずれも実装しない。

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
  name: string;       // "高" | "中" | "低"
  level: 1 | 2 | 3;   // 1=高, 2=中, 3=低
  color: string;
  position: number;
};

type Inquiry = {
  id: number;
  statusId: number;
  priorityId: number;          // NOT NULL（デフォルト「低」）
  title: string;
  description: string | null;
  position: number;
  createdAt: string;           // ISO 8601: "2026-05-01T12:34:56Z"
  updatedAt: string;
};
```

> 注: `Inquiry` の `category` / `assignee` / `labels` フィールド、および `Label` 型は MVP スコープ外。
> `status` / `priority` を nested で返さない設計（クライアント側で `statusId` / `priorityId` から `Map` 引き）。

**JSON 命名規則**
- Rails 側は `jsonapi-serializer` を用い、キーは **camelCase** で返す（Vue/Nuxt 側との親和性）。

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
  "description": "パスワードリセット後にログイン不可"
}
```

`priorityId` を省略した場合は「低」(level=3) のレコード id がサーバ側で割り当てられる。

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
