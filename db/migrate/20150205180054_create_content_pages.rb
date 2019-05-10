class CreateContentPages < ActiveRecord::Migration[4.2]
  def change
    create_table :content_pages do |t|
      t.resource
      t.references :content_chapter, null: false,
                                     foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :content_reading_dynamic_pool
      t.references :content_reading_try_another_pool
      t.references :content_homework_core_pool
      t.references :content_homework_dynamic_pool
      t.references :content_practice_widget_pool

      t.integer :number, null: false
      t.string :title, null: false
      t.string :uuid, null: false
      t.string :version, null: false

      t.text :book_location, null: false

      t.timestamps null: false

      t.resource_index
      t.index [:content_chapter_id, :number], unique: true
      t.index :title
    end

    add_foreign_key :content_pages, :content_pools, column: :content_reading_dynamic_pool_id,
                                                    on_update: :cascade, on_delete: :nullify
    add_foreign_key :content_pages, :content_pools, column: :content_reading_try_another_pool_id,
                                                    on_update: :cascade, on_delete: :nullify
    add_foreign_key :content_pages, :content_pools, column: :content_homework_core_pool_id,
                                                    on_update: :cascade, on_delete: :nullify
    add_foreign_key :content_pages, :content_pools, column: :content_homework_dynamic_pool_id,
                                                    on_update: :cascade, on_delete: :nullify
    add_foreign_key :content_pages, :content_pools, column: :content_practice_widget_pool_id,
                                                    on_update: :cascade, on_delete: :nullify
  end
end
