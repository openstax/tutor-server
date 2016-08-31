class RecalculateTaskStepCounts < ActiveRecord::Migration
  def up
    Tasks::Models::Task.unscoped.preload(task_steps: :tasked).find_each do |task|
      task.update_step_counts!(validate: false)
    end
  end

  def down
  end
end
