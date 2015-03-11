class CreateContentTopics < ActiveRecord::Migration
  def change
    create_table :content_topics do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps null: false

      t.index :name, unique: true
    end
  end
end
