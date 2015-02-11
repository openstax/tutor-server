class CreateInteractives < ActiveRecord::Migration
  def change
    create_table :interactives do |t|
      t.references :resource, null: false
      t.string :title

      t.timestamps null: false
    end

    add_index :interactives, :resource_id, unique: true
    add_index :interactives, :title

    add_foreign_key :interactives, :resources, on_update: :cascade,
                                               on_delete: :cascade
  end
end
