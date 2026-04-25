# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Linear 既定のワークフロー（docs/data-design.md 準拠、6 ステータス）。
# 名前で upsert することでシードの冪等性を確保する。
default_statuses = [
  { name: "Backlog",     color: "#95A5A6", position: 0 },
  { name: "Todo",        color: "#3498DB", position: 1 },
  { name: "In Progress", color: "#F39C12", position: 2 },
  { name: "In Review",   color: "#9B59B6", position: 3 },
  { name: "Done",        color: "#2ECC71", position: 4 },
  { name: "Canceled",    color: "#7F8C8D", position: 5 }
]

default_statuses.each do |attrs|
  status = Status.find_or_initialize_by(name: attrs[:name])
  status.update!(color: attrs[:color], position: attrs[:position])
end

puts "Seeded #{Status.count} statuses."
