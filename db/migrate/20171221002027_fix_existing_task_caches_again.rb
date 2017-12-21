class FixExistingTaskCachesAgain < ActiveRecord::Migration
  def up
    Tasks::Models::Task.find_in_batches(batch_size: 100) do |tasks|
      Tasks::UpdateTaskCaches.perform_later tasks: tasks
    end
  end

  def down
  end
end
