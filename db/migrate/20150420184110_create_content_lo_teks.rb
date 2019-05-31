class CreateContentLoTeks < ActiveRecord::Migration[4.2]
  def change
    create_table :content_lo_teks_tags do |t|
      t.integer :lo_id, null: false
      t.integer :teks_id, null: false
      t.timestamps null: false

      t.index [:lo_id, :teks_id], unique: true, name: 'content_lo_teks_tag_lo_teks_uniq'
    end

    add_foreign_key :content_lo_teks_tags, :content_tags, column: :lo_id,
                                                          on_update: :cascade,
                                                          on_delete: :cascade
    add_foreign_key :content_lo_teks_tags, :content_tags, column: :teks_id,
                                                          on_update: :cascade,
                                                          on_delete: :cascade
  end
end
