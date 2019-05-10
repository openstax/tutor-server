class CreateTasksCourseAssistants < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_course_assistants do |t|
      t.references :entity_course, null: false,
                                   foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :tasks_assistant, null: false,
                                     foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.string :tasks_task_plan_type, null: false
      t.text :settings
      t.text :data

      t.timestamps null: false

      t.index [:entity_course_id, :tasks_task_plan_type],
              unique: true, name: 'index_tasks_course_assistants_on_course_id_and_task_plan_type'
      t.index [:tasks_assistant_id, :entity_course_id],
              name: 'index_tasks_course_assistants_on_assistant_id_and_course_id'
    end
  end
end
