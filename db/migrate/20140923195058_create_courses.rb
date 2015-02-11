class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.references :school
      t.string :name, null: false
      t.string :short_name, null: false
      t.text :description, null: false

      t.timestamps null: false
    end

    add_index :courses, [:school_id, :short_name], unique: true
    add_index :courses, [:name, :school_id], unique: true

    add_foreign_key :courses, :schools, on_update: :cascade,
                                        on_delete: :cascade
  end
end
