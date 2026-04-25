class AddPriorityToInquiries < ActiveRecord::Migration[8.1]
  def change
    # priority_id は NULL 可（NULL = No priority 未設定状態）。
    # priorities 削除時は SET NULL（docs/data-design.md L35）。
    add_reference :inquiries,
                  :priority,
                  type: :bigint,
                  null: true,
                  foreign_key: { on_delete: :nullify },
                  index: { name: "idx_inquiries_priority_id" }
  end
end
