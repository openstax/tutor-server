class CreateSections < ActiveRecord::Migration
  def change
    create_table :sections do |t|
      t.references :klass, null: false
      t.string :name

      t.timestamps null: false
    end

    add_index :sections, [:name, :klass_id], unique: true
    add_index :sections, :klass_id

    add_foreign_key :sections, :klasses, on_update: :cascade,
                                         on_delete: :cascade
  end
end
