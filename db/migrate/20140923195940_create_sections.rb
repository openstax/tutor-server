class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections do |t|
      t.references :klass, null: false
      t.string :name

      t.timestamps null: false

      t.index [:name, :klass_id], unique: true
      t.index :klass_id
    end

    add_foreign_key :sections, :klasses, on_update: :cascade,
                                         on_delete: :cascade
  end
end
