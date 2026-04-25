class CreatePriorities < ActiveRecord::Migration[8.1]
  def change
    create_table :priorities do |t|
      t.string  :name,     null: false, limit: 100
      # Linear 準拠: 0=No priority, 1=Urgent, 2=High, 3=Medium, 4=Low
      t.integer :level,    null: false, limit: 1
      t.string  :color,    null: false, limit: 7
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    # 表示順クエリ高速化（docs/data-design.md L116）
    add_index :priorities, :position
    # level は 5 段階の固定値で同じ level が複数できると意図がブレるため UNIQUE
    add_index :priorities, :level, unique: true

    # data-design.md の CHECK 制約を MySQL ネイティブで再現する（statuses と同方針）
    if connection.adapter_name =~ /mysql/i
      execute <<~SQL
        ALTER TABLE priorities
          ADD CONSTRAINT chk_priorities_name     CHECK (CHAR_LENGTH(name) > 0),
          ADD CONSTRAINT chk_priorities_level    CHECK (level BETWEEN 0 AND 4),
          ADD CONSTRAINT chk_priorities_color    CHECK (color REGEXP '^#[0-9A-Fa-f]{6}$'),
          ADD CONSTRAINT chk_priorities_position CHECK (position >= 0)
      SQL
    end
  end
end
