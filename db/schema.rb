# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_06_22_103516) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "result_comment_masters", force: :cascade do |t|
    t.text "comment"
    t.string "woman_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "result_detaile_masters", force: :cascade do |t|
    t.string "result_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "result_masters", force: :cascade do |t|
    t.string "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "result_string_counts", force: :cascade do |t|
    t.integer "count"
    t.integer "result_detaile_master_id"
    t.integer "result_master_id"
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
