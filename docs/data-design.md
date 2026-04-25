# データ設計

> メインドキュメント: [要件定義書](requirements.md)

## ER図

```
┌────────────┐        ┌──────────────┐        ┌────────────────┐        ┌──────────┐
│  statuses  │ 1    * │  inquiries   │ *    * │ inquiry_labels │ *    1 │  labels  │
│────────────│────────│──────────────│────────│────────────────│────────│──────────│
│ id (PK)    │        │ id (PK)      │        │ inquiry_id(FK) │        │ id (PK)  │
│ name       │        │ status_id FK │        │ label_id  (FK) │        │ name     │
│ color      │        │ priority_id  │        └────────────────┘        │ color    │
│ position   │        │ title        │                                  │created_at│
│created_at  │        │ description  │                                  │updated_at│
│updated_at  │        │ category     │                                  └──────────┘
└────────────┘        │ assignee     │
                      │ position     │        ┌──────────────┐
                      │ created_at   │ *    1 │ priorities   │
                      │ updated_at   │────────│──────────────│
                      └──────────────┘        │ id (PK)      │
                                              │ name         │
                                              │ level        │
                                              │ color        │
                                              │ position     │
                                              │ created_at   │
                                              │ updated_at   │
                                              └──────────────┘
```

**リレーション**
| 関係 | カーディナリティ | 説明 |
|------|---------------|------|
| statuses → inquiries | 1対多 | ステータスは複数の問い合わせを持つ。ステータス削除時は `move_to` で指定した別ステータスへ問い合わせを移動してから削除する（RESTRICT） |
| priorities → inquiries | 1対多 | 優先度は複数の問い合わせに割当可。優先度削除時は `inquiries.priority_id` を NULL に（ON DELETE SET NULL） |
| inquiries → inquiry_labels | 1対多 | 問い合わせは複数のラベルを持てる |
| labels → inquiry_labels | 1対多 | ラベル削除時は `inquiry_labels` も CASCADE DELETE |

---

## テーブル定義（MySQL 8 準拠）

```sql
CREATE TABLE statuses (
  id         BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  color      VARCHAR(7)   NOT NULL,
  position   INT          NOT NULL DEFAULT 0,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_statuses_name     CHECK (CHAR_LENGTH(name) > 0),
  CONSTRAINT chk_statuses_color    CHECK (color REGEXP '^#[0-9A-Fa-f]{6}$'),
  CONSTRAINT chk_statuses_position CHECK (position >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE priorities (
  id         BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  level      TINYINT      NOT NULL,
  color      VARCHAR(7)   NOT NULL,
  position   INT          NOT NULL DEFAULT 0,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_priorities_name  CHECK (CHAR_LENGTH(name) > 0),
  CONSTRAINT chk_priorities_level CHECK (level BETWEEN 0 AND 4),
  CONSTRAINT chk_priorities_color CHECK (color REGEXP '^#[0-9A-Fa-f]{6}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE labels (
  id         BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(100) NOT NULL,
  color      VARCHAR(7)   NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_labels_name  CHECK (CHAR_LENGTH(name) > 0),
  CONSTRAINT chk_labels_color CHECK (color REGEXP '^#[0-9A-Fa-f]{6}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE inquiries (
  id          BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  status_id   BIGINT       UNSIGNED NOT NULL,
  priority_id BIGINT       UNSIGNED NULL,
  title       VARCHAR(255) NOT NULL,
  description TEXT         NULL,
  category    VARCHAR(100) NULL,
  assignee    VARCHAR(100) NULL,
  position    INT          NOT NULL DEFAULT 0,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_inquiries_title    CHECK (CHAR_LENGTH(title) > 0),
  CONSTRAINT chk_inquiries_position CHECK (position >= 0),
  CONSTRAINT fk_inquiries_status   FOREIGN KEY (status_id)   REFERENCES statuses(id)   ON DELETE RESTRICT,
  CONSTRAINT fk_inquiries_priority FOREIGN KEY (priority_id) REFERENCES priorities(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE inquiry_labels (
  inquiry_id BIGINT UNSIGNED NOT NULL,
  label_id   BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (inquiry_id, label_id),
  CONSTRAINT fk_inqlab_inquiry FOREIGN KEY (inquiry_id) REFERENCES inquiries(id) ON DELETE CASCADE,
  CONSTRAINT fk_inqlab_label   FOREIGN KEY (label_id)   REFERENCES labels(id)    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

> Rails マイグレーションで作成するため、実運用では上記 SQL と等価な `create_table` を `db/migrate/` に記述する。

---

## インデックス定義

```sql
-- ステータスの表示順取得を高速化
CREATE INDEX idx_statuses_position ON statuses (position);

-- 優先度の表示順取得を高速化
CREATE INDEX idx_priorities_position ON priorities (position);

-- 問い合わせのステータス別取得を高速化
CREATE INDEX idx_inquiries_status_id ON inquiries (status_id);

-- 問い合わせのステータス別・順番付き取得を高速化（最頻出クエリ）
CREATE INDEX idx_inquiries_status_position ON inquiries (status_id, position);

-- 優先度別の集計・フィルタを高速化
CREATE INDEX idx_inquiries_priority_id ON inquiries (priority_id);

-- ラベル削除時の cascade 検索を高速化
CREATE INDEX idx_inquiry_labels_label_id ON inquiry_labels (label_id);
```

---

## フィールド説明

**statuses**
| フィールド | 型 | NULL | 説明 |
|---|---|---|---|
| id | BIGINT UNSIGNED | NOT NULL | PK、自動採番 |
| name | VARCHAR(100) | NOT NULL | ステータス名、空文字不可 |
| color | VARCHAR(7) | NOT NULL | HEXカラー（例：`#F2C94C`） |
| position | INT | NOT NULL | ボード内の列表示順（0始まり連番） |
| created_at / updated_at | DATETIME | NOT NULL | 自動更新 |

**priorities**
| フィールド | 型 | NULL | 説明 |
|---|---|---|---|
| id | BIGINT UNSIGNED | NOT NULL | PK |
| name | VARCHAR(100) | NOT NULL | 優先度名、空文字不可 |
| level | TINYINT | NOT NULL | 0-4。Linear 準拠：0=No priority, 1=Urgent, 2=High, 3=Medium, 4=Low |
| color | VARCHAR(7) | NOT NULL | HEXカラー |
| position | INT | NOT NULL | 表示順 |
| created_at / updated_at | DATETIME | NOT NULL | 自動更新 |

**labels**
| フィールド | 型 | NULL | 説明 |
|---|---|---|---|
| id | BIGINT UNSIGNED | NOT NULL | PK |
| name | VARCHAR(100) | NOT NULL | ラベル名、空文字不可 |
| color | VARCHAR(7) | NOT NULL | HEXカラー |
| created_at / updated_at | DATETIME | NOT NULL | 自動更新 |

**inquiries**
| フィールド | 型 | NULL | 説明 |
|---|---|---|---|
| id | BIGINT UNSIGNED | NOT NULL | PK |
| status_id | BIGINT UNSIGNED | NOT NULL | FK → statuses.id（RESTRICT） |
| priority_id | BIGINT UNSIGNED | NULL | FK → priorities.id（SET NULL） |
| title | VARCHAR(255) | NOT NULL | 問い合わせタイトル、空文字不可 |
| description | TEXT | NULL | 本文（任意） |
| category | VARCHAR(100) | NULL | カテゴリ文字列（任意。将来マスタ化の余地あり） |
| assignee | VARCHAR(100) | NULL | 担当者（テキスト自由入力） |
| position | INT | NOT NULL | ステータス列内の表示順（0始まり） |
| created_at / updated_at | DATETIME | NOT NULL | 自動更新 |

**inquiry_labels**
| フィールド | 型 | NULL | 説明 |
|---|---|---|---|
| inquiry_id | BIGINT UNSIGNED | NOT NULL | FK → inquiries.id、CASCADE DELETE |
| label_id | BIGINT UNSIGNED | NOT NULL | FK → labels.id、CASCADE DELETE |
| （複合PK） | — | — | (inquiry_id, label_id) の組み合わせで一意 |

---

## position 管理ルール

`position` は 0 始まりの連番で管理する。アプリケーション層（Rails のサービスクラス or モデルメソッド）で並び順を保証する。

| 操作 | position の扱い |
|------|----------------|
| **作成** | 対象スコープ内の現在の最大 position + 1 を設定する |
| **移動（DnD）** | 移動先の position を確定し、影響を受けるすべての行の position をトランザクション内で一括 UPDATE する |
| **削除** | 削除された position より大きいすべての行の position を -1 してギャップを埋める |

**スコープ定義**
- `statuses.position`：ボード全体で一意な連番
- `priorities.position`：全体で一意な連番
- `inquiries.position`：同じ `status_id` 内で一意な連番

---

## シード（初期データ）

Rails の `db/seeds.rb` で以下を投入する想定。

**statuses（Linear の既定ワークフロー準拠、6件）**

| position | name | color |
|---|---|---|
| 0 | Backlog | `#95A5A6` |
| 1 | Todo | `#3498DB` |
| 2 | In Progress | `#F39C12` |
| 3 | In Review | `#9B59B6` |
| 4 | Done | `#2ECC71` |
| 5 | Canceled | `#7F8C8D` |

**priorities（Linear 準拠、5件）**

| position | level | name | color |
|---|---|---|---|
| 0 | 0 | No priority | `#BDC3C7` |
| 1 | 1 | Urgent | `#E74C3C` |
| 2 | 2 | High | `#E67E22` |
| 3 | 3 | Medium | `#F1C40F` |
| 4 | 4 | Low | `#3498DB` |

**labels**：初期データなし（ユーザーが必要に応じて作成）
