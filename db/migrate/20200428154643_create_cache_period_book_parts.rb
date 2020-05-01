class CreateCachePeriodBookParts < ActiveRecord::Migration[5.2]
  def change
    create_table :cache_period_book_parts do |t|
      t.references :course_membership_period,
                   null: false,
                   index: false,
                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.uuid :book_part_uuid, null: false, index: true
      t.boolean :is_page, null: false
      t.integer :num_students, null: false
      t.integer :num_responses, null: false
      t.jsonb :clue, null: false

      t.timestamps
    end

    add_index :cache_period_book_parts, [ :course_membership_period_id, :book_part_uuid ],
              unique: true, name: 'index_period_book_parts_on_period_id_and_book_part_uuid'
  end
end
