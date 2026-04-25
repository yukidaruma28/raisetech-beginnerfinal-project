# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_25_175959) do
  create_table "inquiries", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.bigint "priority_id", null: false
    t.bigint "status_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["priority_id"], name: "idx_inquiries_priority_id"
    t.index ["status_id", "position"], name: "idx_inquiries_status_position"
    t.index ["status_id"], name: "index_inquiries_on_status_id"
    t.check_constraint "`position` >= 0", name: "chk_inquiries_position"
    t.check_constraint "char_length(`title`) > 0", name: "chk_inquiries_title"
  end

  create_table "priorities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "color", limit: 7, null: false
    t.datetime "created_at", null: false
    t.integer "level", limit: 1, null: false
    t.string "name", limit: 100, null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["level"], name: "index_priorities_on_level", unique: true
    t.index ["position"], name: "index_priorities_on_position"
    t.check_constraint "`level` between 0 and 4", name: "chk_priorities_level"
    t.check_constraint "`position` >= 0", name: "chk_priorities_position"
    t.check_constraint "char_length(`name`) > 0", name: "chk_priorities_name"
    t.check_constraint "regexp_like(`color`,_utf8mb4'^#[0-9A-Fa-f]{6}$')", name: "chk_priorities_color"
  end

  create_table "statuses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "color", limit: 7, null: false
    t.datetime "created_at", null: false
    t.string "name", limit: 100, null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_statuses_on_position"
    t.check_constraint "`position` >= 0", name: "chk_statuses_position"
    t.check_constraint "char_length(`name`) > 0", name: "chk_statuses_name"
    t.check_constraint "regexp_like(`color`,_utf8mb4'^#[0-9A-Fa-f]{6}$')", name: "chk_statuses_color"
  end

  add_foreign_key "inquiries", "priorities"
  add_foreign_key "inquiries", "statuses"
end
