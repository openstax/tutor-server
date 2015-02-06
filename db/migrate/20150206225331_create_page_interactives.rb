class CreatePageInteractives < ActiveRecord::Migration
  def change
    create_table :page_interactives do |t|
      t.references :page, null: false
      t.references :interactive, null: false
      t.integer :number, null: false

      t.timestamps null: false
    end

    add_index :page_interactives, [:interactive_id, :page_id], unique: true
    add_index :page_interactives, [:page_id, :number], unique: true

    add_foreign_key :page_interactives, :pages, on_update: :cascade,
                                                on_delete: :cascade
    add_foreign_key :page_interactives, :interactives, on_update: :cascade,
                                                       on_delete: :cascade
  end
end
