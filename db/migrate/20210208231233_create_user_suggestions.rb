class CreateUserSuggestions < ActiveRecord::Migration[5.2]
  def change
    create_table :user_suggestions do |t|
      t.text :content, null: false
      t.integer :topic, default: 0, null: false
    end
  end
end
