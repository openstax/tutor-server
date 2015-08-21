class AddContentEcosystemToTaskPlans < ActiveRecord::Migration
  def change
    add_reference :tasks_task_plans, :content_ecosystem,
                  index: true, foreign_key: { on_update: :cascade, on_delete: :nullify }
  end
end
