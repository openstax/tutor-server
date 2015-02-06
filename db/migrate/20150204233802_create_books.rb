class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.references :resource, null: false

      t.timestamps null: false
    end

    add_index :books, :resource_id, unique: true

    add_foreign_key :books, :resources, on_update: :cascade,
                                        on_delete: :cascade
  end
end
