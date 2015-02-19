class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.references :school
      t.string :name, null: false
      t.string :short_name, null: false
      t.text :description, null: false

      t.timestamps null: false

      t.index [:school_id, :short_name], unique: true
      t.index [:name, :school_id], unique: true
    end

    add_foreign_key :courses, :schools, on_update: :cascade,
                                        on_delete: :cascade
  end
end
