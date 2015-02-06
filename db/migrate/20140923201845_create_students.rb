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
    end

    add_index :students, [:user_id, :klass_id], unique: true
    add_index :students, [:user_id, :section_id], unique: true
    add_index :students, :klass_id
    add_index :students, :section_id
    add_index :students, :random_education_identifier, unique: true
    add_index :students, :student_custom_identifier
    add_index :students, :educator_custom_identifier
    add_index :students, :level

    add_foreign_key :students, :klasses, on_update: :cascade,
                                         on_delete: :cascade
    add_foreign_key :students, :sections, on_update: :cascade,
                                          on_delete: :cascade
    add_foreign_key :students, :users, on_update: :cascade,
                                       on_delete: :cascade
  end
end
