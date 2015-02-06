class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.references :resource, null: false
      t.references :chapter, null: false
      t.integer :number, null: false

      t.timestamps null: false
    end

    add_index :pages, [:resource_id, :chapter_id], unique: true
    add_index :pages, [:chapter_id, :number], unique: true

    add_foreign_key :pages, :resources, on_update: :cascade,
                                        on_delete: :cascade
    add_foreign_key :pages, :chapters, on_update: :cascade, on_delete: :cascade
  end
end
