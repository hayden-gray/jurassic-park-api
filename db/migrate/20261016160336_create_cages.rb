class CreateCages < ActiveRecord::Migration[8.1]
  def change
    create_table :cages do |t|
      t.integer :capacity, null: false
      t.string :power_status, null: false, default: "ACTIVE"

      t.timestamps

      t.check_constraint "capacity > 0", name: "cages_capacity_positive"
      t.check_constraint "power_status IN ('ACTIVE', 'DOWN')", name: "cages_power_status_valid"
    end
  end
end
