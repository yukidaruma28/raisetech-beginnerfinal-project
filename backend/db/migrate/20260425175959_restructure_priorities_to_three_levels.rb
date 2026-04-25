class RestructurePrioritiesToThreeLevels < ActiveRecord::Migration[8.1]
  # 当初の 5 段階 priorities (Linear 準拠: No priority/Urgent/High/Medium/Low) を
  # 3 段階 (高/中/低) + デフォルト「低」に簡素化する。
  # 「priority 未設定」状態を廃止して null チェックを不要にする。
  #
  # MySQL は SET NULL の FK を持つカラムを直接 NOT NULL 化できないため、
  # 「FK 削除 → NOT NULL 化 → FK を RESTRICT で再追加」の順で実行する。
  # また migration の途中で失敗しても再実行できるよう各ステップを冪等にする。
  def up
    # 1. priorities を 3 件に置き換え（既に新体系なら何もしない）
    if !three_level_layout?
      execute "UPDATE inquiries SET priority_id = NULL"
      execute "DELETE FROM priorities"
      execute <<~SQL
        INSERT INTO priorities (name, level, color, position, created_at, updated_at) VALUES
          ('高', 1, '#E74C3C', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
          ('中', 2, '#F1C40F', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
          ('低', 3, '#3498DB', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      SQL
    end

    # 2. NULL の inquiries.priority_id を「低」(level 3) で埋める
    low_id = connection.select_value("SELECT id FROM priorities WHERE level = 3")
    raise "Could not find Low priority" unless low_id
    execute "UPDATE inquiries SET priority_id = #{low_id} WHERE priority_id IS NULL"

    # 3. FK を一旦削除（NOT NULL 化のための前提）
    if foreign_key_exists?(:inquiries, :priorities)
      remove_foreign_key :inquiries, :priorities
    end

    # 4. NOT NULL に変更（既に NOT NULL なら何もしない）
    if priority_id_nullable?
      change_column_null :inquiries, :priority_id, false
    end

    # 5. FK を RESTRICT で再追加
    unless foreign_key_exists?(:inquiries, :priorities)
      add_foreign_key :inquiries, :priorities, on_delete: :restrict
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def three_level_layout?
    rows = connection.select_all("SELECT level, name FROM priorities ORDER BY level").to_a
    return false unless rows.size == 3
    rows.map { |r| [r["level"].to_i, r["name"]] } == [[1, "高"], [2, "中"], [3, "低"]]
  end

  def priority_id_nullable?
    column = connection.columns(:inquiries).find { |c| c.name == "priority_id" }
    column.null
  end
end
