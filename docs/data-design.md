# データ設計

> メインドキュメント: [要件定義書](requirements.md)

## MVP スコープと対象外

本ドキュメントは ER 設計の網羅版（将来拡張を含む）。**MVP では以下を実装しない**（`docs/tech-stack.md` の「採用しないことを明示する技術」参照）:

| 対象外 | 理由 |
|---|---|
| `labels` テーブル + `inquiry_labels` 中間テーブル | シングルユーザー想定で Status × Priority の 2 軸で識別可能なため |
| `inquiries.category` カラム | 同上（カテゴリ分類は不要）|
| `inquiries.assignee` カラム | シングルユーザーのため担当者割当が不要 |
| 5 段階 priority | 3 段階（高/中/低）+ デフォルト「低」に簡素化（後述）|

`priorities` テーブル自体は実装するが、シードと validation を **3 段階（level 1=高, 2=中, 3=低）**に絞る。`inquiries.priority_id` は **NOT NULL**（デフォルトは「低」(level 3) の id）。

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
| priorities → inquiries | 1対多 | 優先度は複数の問い合わせに割当。`priority_id` は NOT NULL のため、削除時は紐づく Inquiry が存在すればエラーで止める（RESTRICT）|
| ~~inquiries → inquiry_labels~~ | ~~1対多~~ | ❌ MVP スコープ外 |
| ~~labels → inquiry_labels~~ | ~~1対多~~ | ❌ MVP スコープ外 |

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
| level | TINYINT | NOT NULL | **MVP では 1..3 のみ採用**（1=高, 2=中, 3=低）。CHECK 制約は 0..4 と広めに残してあるが、アプリ層で 1..3 に絞る。UNIQUE 制約あり |
| color | VARCHAR(7) | NOT NULL | HEXカラー |
| position | INT | NOT NULL | 表示順 |
| created_at / updated_at | DATETIME | NOT NULL | 自動更新 |

**labels** ❌ **MVP スコープ外（実装しない）**
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
| priority_id | BIGINT UNSIGNED | **NOT NULL** | FK → priorities.id（**RESTRICT**）。3 段階に簡素化したことで未設定状態を排除。デフォルトは「低」(level=3) の id |
| title | VARCHAR(255) | NOT NULL | 問い合わせタイトル、空文字不可 |
| description | TEXT | NULL | 本文（任意） |
| ~~category~~ | ~~VARCHAR(100)~~ | ~~NULL~~ | ❌ **MVP スコープ外（実装しない）** |
| ~~assignee~~ | ~~VARCHAR(100)~~ | ~~NULL~~ | ❌ **MVP スコープ外（実装しない）** |
| position | INT | NOT NULL | ステータス列内の表示順（0始まり） |
| created_at / updated_at | DATETIME | NOT NULL | 自動更新 |

**inquiry_labels** ❌ **MVP スコープ外（実装しない）**
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

**priorities（3 段階、デフォルト「低」）**

| position | level | name | color |
|---|---|---|---|
| 0 | 1 | 高 | `#E74C3C` |
| 1 | 2 | 中 | `#F1C40F` |
| 2 | 3 | 低 | `#3498DB` |

新規 `Inquiry` 作成時に `priority` を省略した場合は level=3（低）の id をデフォルトとして割り当てる。

**labels**: ❌ MVP スコープ外（実装しない）
