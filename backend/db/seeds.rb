# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# 既存データを完全リセット（ドメイン変換後のクリーンな状態から再構築する）。
# Priority は固定 3 件なので upsert のままでよい。
Inquiry.delete_all
Status.delete_all

# 視聴管理ボード用ステータス（4 件）。
default_statuses = [
  { name: "見たい",   color: "#3498DB", position: 0 },
  { name: "視聴中",   color: "#F39C12", position: 1 },
  { name: "視聴済み", color: "#2ECC71", position: 2 },
  { name: "断念",     color: "#7F8C8D", position: 3 },
]

default_statuses.each do |attrs|
  status = Status.find_or_initialize_by(name: attrs[:name])
  status.update!(color: attrs[:color], position: attrs[:position])
end

puts "Seeded #{Status.count} statuses."

# 3 段階の優先度（高 / 中 / 低）。デフォルトは「低」(level 3)。
# level は 1..3 の値で UNIQUE 制約。level をキーに upsert して冪等性を担保。
default_priorities = [
  { level: 1, name: "高", color: "#E74C3C", position: 0 },
  { level: 2, name: "中", color: "#F1C40F", position: 1 },
  { level: 3, name: "低", color: "#3498DB", position: 2 }
]

default_priorities.each do |attrs|
  priority = Priority.find_or_initialize_by(level: attrs[:level])
  priority.update!(name: attrs[:name], color: attrs[:color], position: attrs[:position])
end

puts "Seeded #{Priority.count} priorities."

# サンプル作品（8 件）。各ステータスに散らばるよう配置。
# 気になり度（priority_level）は 1=高 / 2=中 / 3=低。
default_inquiries = [
  { status_name: "見たい",   priority_level: 1, title: "進撃の巨人 ファイナルシーズン",
    description: "完結編まで一気に見たい。", position: 0 },
  { status_name: "見たい",   priority_level: 2, title: "インターステラー",
    description: "SF 名作として名高い。時間があるときに。", position: 1 },
  { status_name: "見たい",   priority_level: 3, title: "ワンピース",
    description: "長編すぎて踏み出せていない。", position: 2 },

  { status_name: "視聴中",   priority_level: 1, title: "鬼滅の刃 柱稽古編",
    description: "毎話作画が神がかっている。", position: 0 },
  { status_name: "視聴中",   priority_level: 2, title: "オッペンハイマー",
    description: "3 時間あるので少しずつ消化中。", position: 1 },

  { status_name: "視聴済み", priority_level: 1, title: "呪術廻戦 渋谷事変",
    description: "五条vs漏瑚が圧巻だった。", position: 0 },
  { status_name: "視聴済み", priority_level: 2, title: "君の名は。",
    description: "何度見ても感動する。", position: 1 },

  { status_name: "断念",     priority_level: 3, title: "NANA",
    description: "配信終了で途中から見られなくなった。", position: 0 },
]

default_inquiries.each do |attrs|
  status   = Status.find_by!(name: attrs[:status_name])
  priority = Priority.find_by!(level: attrs[:priority_level])
  inquiry  = Inquiry.find_or_initialize_by(title: attrs[:title])
  inquiry.update!(
    status:      status,
    priority:    priority,
    description: attrs[:description],
    position:    attrs[:position]
  )
end

puts "Seeded #{Inquiry.count} inquiries."
