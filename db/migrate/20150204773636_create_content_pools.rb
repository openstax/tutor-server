class CreateContentPools < ActiveRecord::Migration[4.2]
  def change
    create_table :content_pools do |t|
      t.references :content_ecosystem, null: false, index: true,
                                       foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :uuid, null: false
      t.integer :pool_type, null: false
      t.text :content_exercise_ids

      t.timestamps null: false

      t.index :uuid, unique: true
      t.index :pool_type
    end
  end
end
