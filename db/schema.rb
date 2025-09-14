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

ActiveRecord::Schema.define(version: 2019_06_22_103516) do

  create_table "rank_masters", force: :cascade do |t|
    t.string "rank"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "result_comment_masters", force: :cascade do |t|
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "result_detaile_masters", force: :cascade do |t|
    t.text "detaile"
    t.string "woman_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "result_string_counts", force: :cascade do |t|
    t.integer "count"
    t.integer "result_comment_master_id"
    t.integer "rank_master_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "string_counts", force: :cascade do |t|
    t.string "unicode"
    t.string "chara"
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
