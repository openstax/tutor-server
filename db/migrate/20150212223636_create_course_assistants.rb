class CreateCourseAssistants < ActiveRecord::Migration
  def change
    create_table :course_assistants do |t|
      t.references :course, null: false
      t.references :assistant, null: false
      t.text :settings
      t.text :data

      t.timestamps null: false

      t.index [:course_id, :assistant_id], unique: true
      t.index :assistant_id
    end

    add_foreign_key :course_assistants, :courses
    add_foreign_key :course_assistants, :assistants
  end
end
