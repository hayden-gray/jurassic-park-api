class CreateSpecies < ActiveRecord::Migration[8.1]
  def change
    create_table :species do |t|
      t.string :name, null: false
      t.string :diet, null: false

      t.timestamps

      t.index :name, unique: true
      t.check_constraint "diet IN ('herbivore', 'carnivore')", name: "species_diet_valid"
    end
  end
end
