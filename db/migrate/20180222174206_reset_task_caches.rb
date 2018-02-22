class ResetTaskCaches < ActiveRecord::Migration
  def up
    Tasks::Models::Task.select(:id).find_in_batches(batch_size: 100) do |tasks|
      Tasks::UpdateTaskCaches.set(queue: :lowest_priority)
                             .perform_later(task_ids: tasks.map(&:id), queue: 'lowest_priority')
    end
  end

  def down
  end
end
