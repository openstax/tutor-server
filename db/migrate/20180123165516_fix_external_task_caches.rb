class FixExternalTaskCaches < ActiveRecord::Migration
  def up
    Tasks::Models::Task.external.find_in_batches(batch_size: 100) do |tasks|
      Tasks::UpdateTaskCaches.perform_later tasks: tasks
    end
  end

  def down
  end
end
