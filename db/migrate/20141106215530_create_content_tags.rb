class CreateContentTags < ActiveRecord::Migration
  def change
    create_table :content_tags do |t|
      t.string :value, null: false
      t.integer :tag_type, null: false, default: 0
      t.string :name
      t.text :description
      t.boolean :visible, default: true

      t.timestamps null: false

      t.index :value, unique: true
      t.index :tag_type
    end
  end
end
