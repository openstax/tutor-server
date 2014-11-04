class CreateInteractives < ActiveRecord::Migration
  def change
    create_table :interactives do |t|
      t.references :resource, null: false

      t.timestamps null: false
    end

    add_index :interactives, :resource_id
  end
end
