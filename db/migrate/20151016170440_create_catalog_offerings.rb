class CreateCatalogOfferings < ActiveRecord::Migration

  def change
    create_table :catalog_offerings do |t|
      t.string :identifier, null: false, index: { unique: true }
      t.references :content_ecosystem, null: true, index: true
      t.hstore :flags, null: false, default: {}
      t.string :description, :webview_url, :pdf_url, null: false
      t.timestamps null: false
    end

    add_foreign_key :catalog_offerings, :content_ecosystems, on_update: :cascade, on_delete: :cascade
  end

end
