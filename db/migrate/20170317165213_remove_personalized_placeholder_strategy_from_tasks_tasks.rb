class RemovePersonalizedPlaceholderStrategyFromTasksTasks < ActiveRecord::Migration
  def change
    remove_column :tasks_tasks, :personalized_placeholder_strategy, :text
  end
end
