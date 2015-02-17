class CreateResourceTopics < ActiveRecord::Migration
  def change
    create_table :resource_topics do |t|
      t.references :resource, null: false
      t.references :topic, null: false
      t.integer :number, null: false

      t.timestamps null: false
    end

    add_index :resource_topics, [:topic_id, :resource_id], unique: true
    add_index :resource_topics, [:resource_id, :number], unique: true

    add_foreign_key :resource_topics, :resources, on_update: :cascade,
                                                  on_delete: :cascade
    add_foreign_key :resource_topics, :topics, on_update: :cascade,
                                               on_delete: :cascade
  end
end
