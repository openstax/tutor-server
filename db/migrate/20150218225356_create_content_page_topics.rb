class CreateContentPageTopics < ActiveRecord::Migration
  def change
    create_table :content_page_topics do |t|
      t.references :content_page, null: false
      t.references :content_topic, null: false
      t.integer :number, null: false

      t.timestamps null: false

      t.index [:content_topic_id, :content_page_id], unique: true, name: 'content_topic_page_ids_unique'
      t.index [:content_page_id, :number], unique: true
    end

    add_foreign_key :content_page_topics, :pages, on_update: :cascade,
                                                  on_delete: :cascade
    add_foreign_key :content_page_topics, :topics, on_update: :cascade,
                                                   on_delete: :cascade
  end
end
