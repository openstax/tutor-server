class CreateContentLoTeks < ActiveRecord::Migration
  def change
    create_table :content_lo_teks_tags do |t|
      t.integer :lo_id, null: false
      t.integer :teks_id, null: false
      t.timestamps null: false

      t.index [:lo_id, :teks_id], unique: true, name: 'content_lo_teks_tag_lo_teks_uniq'
    end

    add_foreign_key :content_lo_teks_tags, :content_tags, column: :lo_id
    add_foreign_key :content_lo_teks_tags, :content_tags, column: :teks_id
  end
end
