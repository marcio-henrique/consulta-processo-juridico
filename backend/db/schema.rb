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

ActiveRecord::Schema[8.1].define(version: 2026_10_08_000006) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "lawsuits", force: :cascade do |t|
    t.string "number", null: false
    t.string "forum", null: false
    t.string "court", null: false
    t.decimal "value", precision: 15, scale: 2, null: false
    t.integer "number_of_authors", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_lawsuits_on_number", unique: true
  end

  create_table "movements", force: :cascade do |t|
    t.bigint "lawsuit_id", null: false
    t.date "occurred_on", null: false
    t.string "title", null: false
    t.text "content"
    t.integer "source_row", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lawsuit_id", "occurred_on", "source_row"], name: "index_movements_on_lawsuit_and_display_order", order: { occurred_on: :desc }
    t.index ["lawsuit_id"], name: "index_movements_on_lawsuit_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_sessions_on_token_digest", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "summaries", force: :cascade do |t|
    t.bigint "lawsuit_id", null: false
    t.text "body", null: false
    t.string "movements_digest", null: false
    t.string "prompt_version", null: false
    t.string "provider", null: false
    t.string "model", null: false
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lawsuit_id", "movements_digest", "prompt_version", "model"], name: "index_summaries_on_cache_key", unique: true
    t.index ["lawsuit_id"], name: "index_summaries_on_lawsuit_id"
  end

  create_table "summary_feedbacks", force: :cascade do |t|
    t.bigint "summary_id", null: false
    t.bigint "user_id", null: false
    t.boolean "helpful", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["summary_id", "user_id"], name: "index_summary_feedbacks_on_summary_id_and_user_id", unique: true
    t.index ["summary_id"], name: "index_summary_feedbacks_on_summary_id"
    t.index ["user_id"], name: "index_summary_feedbacks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "movements", "lawsuits", on_delete: :cascade
  add_foreign_key "sessions", "users", on_delete: :cascade
  add_foreign_key "summaries", "lawsuits"
  add_foreign_key "summary_feedbacks", "summaries"
  add_foreign_key "summary_feedbacks", "users"
end
