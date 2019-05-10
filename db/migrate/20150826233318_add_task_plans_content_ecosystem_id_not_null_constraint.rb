class AddTaskPlansContentEcosystemIdNotNullConstraint < ActiveRecord::Migration[4.2]
  def change
    # This migration will fail if any task_plans already have a null content_ecosystem_id
    change_column_null :tasks_task_plans, :content_ecosystem_id, false

    # Since the column is now not null, deletes should cascade to the task_plan
    remove_foreign_key :tasks_task_plans, :content_ecosystems
    add_foreign_key :tasks_task_plans, :content_ecosystems, on_update: :cascade,
                                                            on_delete: :cascade
  end
end
