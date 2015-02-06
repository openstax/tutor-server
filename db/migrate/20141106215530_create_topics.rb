class CreateTopics < ActiveRecord::Migration
  def change
    create_table :topics do |t|
      t.references :klass, null: false
      t.string :name, null: false

      t.timestamps null: false
    end

    add_index :topics, [:klass_id, :name], unique: true

    add_foreign_key :topics, :klasses, on_update: :cascade,
                                       on_delete: :cascade
  end
end
