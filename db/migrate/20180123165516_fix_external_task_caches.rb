class FixExternalTaskCaches < ActiveRecord::Migration
  def up
    Tasks::Models::Task.select(:id).external.find_in_batches(batch_size: 100) do |tasks|
      Tasks::UpdateTaskCaches.perform_later task_ids: tasks.map(&:id)
    end
  end

  def down
  end
end
