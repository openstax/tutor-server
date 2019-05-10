class CreateContentTags < ActiveRecord::Migration[4.2]
  def change
    create_table :content_tags do |t|
      t.references :content_ecosystem, null: false, index: true,
                                       foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :value, null: false
      t.integer :tag_type, null: false, default: 0
      t.string :name
      t.text :description
      t.string :data
      t.boolean :visible

      t.timestamps null: false

      t.index [:value, :content_ecosystem_id], unique: true
      t.index :tag_type
    end
  end
end
