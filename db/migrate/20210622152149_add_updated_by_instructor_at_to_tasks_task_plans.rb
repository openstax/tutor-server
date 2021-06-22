class AddUpdatedByInstructorAtToTasksTaskPlans < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_task_plans, :updated_by_instructor_at, :datetime
  end
end
