class AddTaskContentEcosystem < ActiveRecord::Migration
  def change
    add_reference :tasks_tasks, :content_ecosystem,
                  foreign_key: { on_update: :cascade, on_delete: :nullify }
  end
end
