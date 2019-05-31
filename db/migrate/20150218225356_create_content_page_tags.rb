class CreateContentPageTags < ActiveRecord::Migration[4.2]
  def change
    create_table :content_page_tags do |t|
      t.references :content_page, null: false,
                                  foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :content_tag, null: false, index: true,
                                 foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.timestamps null: false

      t.index [:content_page_id, :content_tag_id], unique: true
    end
  end
end
