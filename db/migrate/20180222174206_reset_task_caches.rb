class ResetTaskCaches < ActiveRecord::Migration[4.2]
  def up
    Tasks::Models::Task.select(:id).find_in_batches(batch_size: 100) do |tasks|
      Tasks::UpdateTaskCaches.set(queue: :migration)
                             .perform_later(task_ids: tasks.map(&:id), queue: 'migration')
    end
  end

  def down
  end
end
