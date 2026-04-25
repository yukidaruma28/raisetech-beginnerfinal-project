class CreateInquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :inquiries do |t|
      # statuses(id) への FK。ステータス削除は RESTRICT し、保有 inquiries が残る
      # 場合は事前に move_to で逃がす運用（docs/data-design.md 参照）。
      t.references :status, null: false, foreign_key: { on_delete: :restrict }, type: :bigint

      t.string  :title,       null: false, limit: 255
      t.text    :description, null: true
      t.integer :position,    null: false, default: 0

      t.timestamps
    end

    # 単独の status_id インデックスは t.references で自動生成されるため、
    # ここでは複合インデックスのみ追加する（最頻出クエリ: status 列内の position 順取得）。
    add_index :inquiries, [:status_id, :position], name: "idx_inquiries_status_position"

    # data-design.md の CHECK 制約を MySQL ネイティブで再現する。
    # status の縦串と同じ方針（DB 層でも整合性を担保）。
    if connection.adapter_name =~ /mysql/i
      execute <<~SQL
        ALTER TABLE inquiries
          ADD CONSTRAINT chk_inquiries_title    CHECK (CHAR_LENGTH(title) > 0),
          ADD CONSTRAINT chk_inquiries_position CHECK (position >= 0)
      SQL
    end
  end
end
