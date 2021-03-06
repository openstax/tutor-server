class AddTaskPlanAndWithdrawnAtToTaskCaches < ActiveRecord::Migration[5.2]
  def change
    add_reference :tasks_task_caches, :tasks_task_plan,
                  foreign_key: { on_update: :cascade, on_delete: :cascade }
    add_column :tasks_task_caches, :withdrawn_at, :datetime

    reversible do |dir|
      dir.up do
        Tasks::Models::Task.select(:id).find_in_batches(batch_size: 100) do |tasks|
          Tasks::UpdateTaskCaches.set(queue: :migration)
                                 .perform_later(task_ids: tasks.map(&:id), queue: 'migration')
        end
      end
    end
  end
end
