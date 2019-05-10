class CreateCatalogOfferings < ActiveRecord::Migration[4.2]

  def change
    create_table :catalog_offerings do |t|
      t.string :identifier, null: false, index: { unique: true }
      t.references :content_ecosystem, null: true, index: true
      t.boolean :is_tutor, :is_concept_coach, null: false, default: 'f'
      t.string :description, :webview_url, :pdf_url, null: false
      t.timestamps null: false
    end

    add_foreign_key :catalog_offerings, :content_ecosystems, on_update: :cascade, on_delete: :cascade

    add_column :course_profile_profiles, :catalog_offering_identifier, :string
  end

end
