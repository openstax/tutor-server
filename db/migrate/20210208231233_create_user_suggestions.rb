class CreateUserSuggestions < ActiveRecord::Migration[5.2]
  def change
    create_table :user_suggestions do |t|
      t.text :content, null: false
      t.integer :topic, default: 0, null: false
      t.references :user_profile, null: false,
        foreign_key: { on_update: :cascade, on_delete: :cascade }
    end
  end
end
