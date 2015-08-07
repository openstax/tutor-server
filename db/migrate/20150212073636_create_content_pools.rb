class CreateContentPools < ActiveRecord::Migration
  def change
    create_table :content_pools do |t|
      t.references :content_page, null: false, foreign_key: { on_update: :cascade,
                                                              on_delete: :cascade }
      t.string :uuid, null: false
      t.integer :pool_type, null: false
      t.text :content_exercise_ids

      t.timestamps null: false

      t.index :uuid, unique: true
      t.index [:content_page_id, :pool_type], unique: true
    end
  end
end
