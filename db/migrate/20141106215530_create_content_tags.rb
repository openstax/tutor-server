class CreateContentTags < ActiveRecord::Migration
  def change
    create_table :content_tags do |t|
      t.references :content_ecosystem, null: false
      t.string :value, null: false
      t.integer :tag_type, null: false, default: 0
      t.string :name
      t.text :description
      t.string :data
      t.boolean :visible

      t.timestamps null: false

      t.index [:content_ecosystem_id, :value], unique: true
      t.index :tag_type
    end
  end
end
