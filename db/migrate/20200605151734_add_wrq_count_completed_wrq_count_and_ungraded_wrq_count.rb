class AddWrqCountCompletedWrqCountAndUngradedWrqCount < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasks, :completed_wrq_step_count, :integer, default: 0, null: false
    rename_column :tasks_tasks, :ungraded_step_count, :ungraded_wrq_step_count

    add_column :tasks_tasking_plans, :completed_wrq_step_count, :integer, default: 0, null: false
    add_column :tasks_tasking_plans, :ungraded_wrq_step_count, :integer, default: 0, null: false

    add_column :tasks_task_plans, :wrq_count, :integer, default: 0, null: false
    add_column :tasks_task_plans, :completed_wrq_step_count, :integer, default: 0, null: false
    rename_column :tasks_task_plans, :ungraded_step_count, :ungraded_wrq_step_count

    wrq_time = DateTime.new 2020, 6

    tt = Tasks::Models::Task.arel_table
    Tasks::Models::Task
      .preload(task_steps: :tasked)
      .where(tt[:created_at].gt wrq_time)
      .find_each do |task|
      task.update_cached_attributes.save!
    end

    tp = Tasks::Models::TaskPlan.arel_table
    Tasks::Models::TaskPlan.where(tp[:created_at].gt wrq_time).find_each do |task_plan|
      task_plan.set_wrq_count
      task_plan.save!
      task_plan.update_wrq_step_counts!
    end
  end
end
