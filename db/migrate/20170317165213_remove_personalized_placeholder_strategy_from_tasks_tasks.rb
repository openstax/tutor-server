class RemovePersonalizedPlaceholderStrategyFromTasksTasks < ActiveRecord::Migration[4.2]
  def change
    remove_column :tasks_tasks, :personalized_placeholder_strategy, :text
  end
end
