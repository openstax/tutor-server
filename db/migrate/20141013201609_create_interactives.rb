class CreateInteractives < ActiveRecord::Migration
  def change
    create_table :interactives do |t|
      t.integer :resource_id, null: false

      t.timestamps null: false
    end

    add_index :interactives, :resource_id
    change_column :readings, :resource_id, :integer, null: false
  end
end
