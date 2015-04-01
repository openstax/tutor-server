class CreateContentTags < ActiveRecord::Migration
  def change
    create_table :content_tags do |t|
      t.string :name, null: false
      t.integer :tag_type, null: false, default: 0
      t.text :description

      t.timestamps null: false

      t.index :name, unique: true
      t.index :tag_type
    end
  end
end
