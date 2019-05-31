class CreateTasksConceptCoachTasks < ActiveRecord::Migration[4.2]
  def change
    create_table :tasks_concept_coach_tasks do |t|
      t.references :entity_task, null: false, index: { unique: true },
                                 foreign_key: { on_update: :cascade, on_delete: :cascade }
      t.references :content_page, null: false, index: true,
                                  foreign_key: { on_update: :cascade, on_delete: :cascade }

      t.timestamps null: false
    end
  end
end
