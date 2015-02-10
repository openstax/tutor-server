class CreatePageTopics < ActiveRecord::Migration
  def change
    create_table :page_topics do |t|
      t.references :page, null: false
      t.references :topic, null: false
      t.integer :number, null: false

      t.timestamps null: false
    end

    add_index :page_topics, [:topic_id, :page_id], unique: true
    add_index :page_topics, [:page_id, :number], unique: true

    add_foreign_key :page_topics, :pages, on_update: :cascade,
                                          on_delete: :cascade
    add_foreign_key :page_topics, :topics, on_update: :cascade,
                                           on_delete: :cascade
  end
end
