class AddDueDateFieldsToTaskSteps < ActiveRecord::Migration
  def change
    if reverting?
      # ADDING while reverting
      remove_column :tasks_task_steps, :completed_at, :datetime

      Tasks::Models::TaskStep.complete.find_each do |step|
        step.update_attributes(completed_at: step.last_completed_at)
      end

      # REMOVING while reverting
      add_column :tasks_task_steps, :first_completed_at, :datetime
      add_column :tasks_task_steps, :last_completed_at, :datetime
    else
      add_column :tasks_task_steps, :first_completed_at, :datetime
      add_column :tasks_task_steps, :last_completed_at, :datetime
      Tasks::Models::TaskStep.where('completed_at IS NOT NULL').find_each(&:complete)
      remove_column :tasks_task_steps, :completed_at, :datetime
    end
  end
end
