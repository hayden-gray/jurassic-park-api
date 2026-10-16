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

ActiveRecord::Schema[8.1].define(version: 2026_10_16_170002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cages", force: :cascade do |t|
    t.integer "capacity", null: false
    t.string "power_status", default: "ACTIVE", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "capacity > 0", name: "cages_capacity_positive"
    t.check_constraint "power_status::text = ANY (ARRAY['ACTIVE'::character varying::text, 'DOWN'::character varying::text])", name: "cages_power_status_valid"
  end

  create_table "dinosaurs", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "species_id", null: false
    t.bigint "cage_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cage_id"], name: "index_dinosaurs_on_cage_id"
    t.index ["species_id"], name: "index_dinosaurs_on_species_id"
    t.check_constraint "btrim(name::text) <> ''::text", name: "dinosaurs_name_not_blank"
  end

  create_table "species", force: :cascade do |t|
    t.string "name", null: false
    t.string "diet", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_species_on_name", unique: true
    t.check_constraint "diet::text = ANY (ARRAY['herbivore'::character varying, 'carnivore'::character varying]::text[])", name: "species_diet_valid"
  end

  add_foreign_key "dinosaurs", "cages", on_delete: :restrict
  add_foreign_key "dinosaurs", "species", on_delete: :restrict
end
