class CreateDinosaurs < ActiveRecord::Migration[8.1]
  def change
    create_table :dinosaurs do |t|
      t.string :name, null: false
      t.references :species, null: false, foreign_key: { on_delete: :restrict }
      t.references :cage, null: true, foreign_key: { on_delete: :restrict }

      t.timestamps

      t.check_constraint "btrim(name) <> ''", name: "dinosaurs_name_not_blank"
    end
  end
end
