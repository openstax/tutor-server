class CreateTasksCourseAssistants < ActiveRecord::Migration
  def change
    create_table :tasks_course_assistants do |t|
      t.references :entity_course, null: false
      t.references :tasks_assistant, null: false
      t.text :settings
      t.text :data

      t.timestamps null: false

      t.index [:entity_course_id, :tasks_assistant_id], unique: true,
              name: 'tasks_course_assistant_course_on_assistant_unique'
      t.index :tasks_assistant_id
    end

    add_foreign_key :tasks_course_assistants, :entity_courses
    add_foreign_key :tasks_course_assistants, :tasks_assistants
  end
end
