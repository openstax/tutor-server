class CreateInteractiveTopics < ActiveRecord::Migration
  def change
    create_table :interactive_topics do |t|
      t.references :interactive, null: false
      t.references :topic, null: false

      t.timestamps null: false
    end

    add_index :interactive_topics, [:interactive_id, :topic_id], unique: true
    add_index :interactive_topics, :topic_id

    add_foreign_key :interactive_topics, :interactives, on_update: :cascade,
                                                        on_delete: :cascade
    add_foreign_key :interactive_topics, :topics, on_update: :cascade,
                                                  on_delete: :cascade
  end
end
