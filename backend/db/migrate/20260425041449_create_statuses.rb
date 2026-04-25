class CreateStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :statuses do |t|
      t.string  :name,     null: false, limit: 100
      t.string  :color,    null: false, limit: 7
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :statuses, :position

    # data-design.md の CHECK 制約を MySQL ネイティブで再現する。
    # rack-cors / jsonapi-serializer 同様、データ整合性は DB 層でも担保する。
    if connection.adapter_name =~ /mysql/i
      execute <<~SQL
        ALTER TABLE statuses
          ADD CONSTRAINT chk_statuses_name     CHECK (CHAR_LENGTH(name) > 0),
          ADD CONSTRAINT chk_statuses_color    CHECK (color REGEXP '^#[0-9A-Fa-f]{6}$'),
          ADD CONSTRAINT chk_statuses_position CHECK (position >= 0)
      SQL
    end
  end
end
