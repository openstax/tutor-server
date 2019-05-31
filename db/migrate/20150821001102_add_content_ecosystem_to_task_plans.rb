class AddContentEcosystemToTaskPlans < ActiveRecord::Migration[4.2]
  def change
    add_reference :tasks_task_plans, :content_ecosystem,
                  index: true, foreign_key: { on_update: :cascade, on_delete: :nullify }
  end
end
