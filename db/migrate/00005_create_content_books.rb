class CreateContentBooks < ActiveRecord::Migration
  def change
    create_table :content_books do |t|
      t.resource
      t.references :content_ecosystem, null: false,
                                       index: true,
                                       foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :title, null: false
      t.string :uuid
      t.string :version

      t.timestamps null: false

      t.resource_index
      t.index :title
    end
  end
end
