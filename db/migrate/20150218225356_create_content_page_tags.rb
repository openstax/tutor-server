class CreateContentPageTags < ActiveRecord::Migration
  def change
    create_table :content_page_tags do |t|
      t.references :content_page, null: false
      t.references :content_tag, null: false

      t.timestamps null: false

      t.index [:content_page_id, :content_tag_id], unique: true
      t.index :content_tag_id
    end

    add_foreign_key :content_page_tags, :content_pages, on_update: :cascade,
                                                        on_delete: :cascade
    add_foreign_key :content_page_tags, :content_tags, on_update: :cascade,
                                                       on_delete: :cascade
  end
end
