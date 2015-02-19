class CreateCourses < ActiveRecord::Migration
  def change
    create_table :courses do |t|
      t.string :school, null: false
      t.string :name, null: false
      t.string :short_name, null: false
      t.string :time_zone, null: false
      t.text :description, null: false
      t.text :approved_emails, null: false
      t.boolean :allow_student_custom_identifier, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.datetime :visible_at
      t.datetime :invisible_at

      t.timestamps null: false

      t.index [:school, :name], unique: true
      t.index [:short_name, :school], unique: true
      t.index [:ends_at, :starts_at]
      t.index [:invisible_at, :visible_at]
    end
  end
end
