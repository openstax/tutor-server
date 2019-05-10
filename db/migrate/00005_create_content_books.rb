class CreateContentBooks < ActiveRecord::Migration[4.2]
  def change
    create_table :content_books do |t|
      t.resource
      t.references :content_ecosystem, null: false, index: true,
                                       foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :title, null: false
      t.string :uuid, null: false
      t.string :version, null: false

      t.timestamps null: false

      t.resource_index
      t.index :title
    end
  end
end
