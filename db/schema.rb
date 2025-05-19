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

ActiveRecord::Schema[8.0].define(version: 2025_04_03_230741) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "meetup_areas", force: :cascade do |t|
    t.string "name", null: false
    t.string "location"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meetup_days", force: :cascade do |t|
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meetups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer "user_id", null: false
    t.integer "state", default: 0, null: false
    t.integer "meetup_area_id"
    t.integer "meetup_day_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["meetup_area_id"], name: "index_meetups_on_meetup_area_id"
    t.index ["meetup_day_id"], name: "index_meetups_on_meetup_day_id"
    t.index ["name"], name: "index_meetups_on_name"
    t.index ["state"], name: "index_meetups_on_state"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id"
    t.string "hashed_key"
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "uid", null: false
    t.string "login", null: false
    t.string "email", null: false
    t.boolean "site_admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["login"], name: "index_users_on_login"
    t.index ["uid"], name: "index_users_on_uid"
  end
end
