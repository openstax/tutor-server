class CreateStudents < ActiveRecord::Migration
  def change
    create_table :students do |t|
      t.references :klass, null: false
      t.references :section, null: true
      t.references :user, null: false
      t.integer :level
      t.boolean :has_dropped
      t.string :student_custom_identifier
      t.string :educator_custom_identifier
      t.string :random_education_identifier, null: false

      t.timestamps null: false

      t.index [:user_id, :klass_id], unique: true
      t.index [:user_id, :section_id], unique: true
      t.index :klass_id
      t.index :section_id
      t.index :random_education_identifier, unique: true
      t.index :student_custom_identifier
      t.index :educator_custom_identifier
      t.index :level
    end



    add_foreign_key :students, :klasses, on_update: :cascade,
                                         on_delete: :cascade
    add_foreign_key :students, :sections, on_update: :cascade,
                                          on_delete: :cascade
    add_foreign_key :students, :users, on_update: :cascade,
                                       on_delete: :cascade
  end
end
