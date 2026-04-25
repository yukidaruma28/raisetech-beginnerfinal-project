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

# Inquiry のサンプルデータ（縦串 read-only スライス用、計 10 件）。
# 各 Status に散らばるよう配置: Backlog 2 / Todo 3 / In Progress 2 / In Review 1 / Done 1 / Canceled 1。
# title をキーに upsert して冪等性を担保する（同タイトルが複数できないようにする）。
default_inquiries = [
  { status_name: "Backlog",     title: "ロゴデザインのリニューアル検討",
    description: "コーポレートサイトのロゴを刷新したい。候補案を 3 案ほど用意。", position: 0 },
  { status_name: "Backlog",     title: "問い合わせフォームの項目追加",
    description: "業種選択のドロップダウンを追加したい。",                              position: 1 },

  { status_name: "Todo",        title: "ヘッダーのナビゲーション改修",
    description: "PC とスマホでメニュー構成を分けたい。",                               position: 0 },
  { status_name: "Todo",        title: "FAQ ページの作成",
    description: "よくある質問を 10 件ほどまとめてページ化する。",                      position: 1 },
  { status_name: "Todo",        title: "メールテンプレートの整備",
    description: nil,                                                                  position: 2 },

  { status_name: "In Progress", title: "API のレスポンス速度改善",
    description: "/api/inquiries の N+1 を解消し p95 を 200ms 以下にする。",            position: 0 },
  { status_name: "In Progress", title: "管理画面のダークモード対応",
    description: "shadcn-vue のテーマ切替を導入する。",                                  position: 1 },

  { status_name: "In Review",   title: "ユニットテストの追加",
    description: "Inquiry モデルの validations を網羅する。",                           position: 0 },

  { status_name: "Done",        title: "Docker Compose の MySQL 設定",
    description: "MySQL 8 のコンテナを追加し、開発環境を統一した。",                    position: 0 },

  { status_name: "Canceled",    title: "Slack 通知連携",
    description: "要件が未確定のため一旦見送り。",                                       position: 0 }
]

default_inquiries.each do |attrs|
  status = Status.find_by!(name: attrs[:status_name])
  inquiry = Inquiry.find_or_initialize_by(title: attrs[:title])
  inquiry.update!(
    status:      status,
    description: attrs[:description],
    position:    attrs[:position]
  )
end

puts "Seeded #{Inquiry.count} inquiries."
