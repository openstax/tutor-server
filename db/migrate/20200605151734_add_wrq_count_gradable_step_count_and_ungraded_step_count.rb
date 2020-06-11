class AddWrqCountGradableStepCountAndUngradedStepCount < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_tasks, :gradable_step_count, :integer, default: 0, null: false

    add_column :tasks_tasking_plans, :gradable_step_count, :integer, default: 0, null: false
    add_column :tasks_tasking_plans, :ungraded_step_count, :integer, default: 0, null: false

    add_column :tasks_task_plans, :wrq_count, :integer, default: 0, null: false
    add_column :tasks_task_plans, :gradable_step_count, :integer, default: 0, null: false

    update_time = DateTime.new 2020, 6

    tt = Tasks::Models::Task.arel_table
    Tasks::Models::Task
      .preload(task_steps: :tasked)
      .where(tt[:created_at].gt update_time)
      .find_each do |task|
      task.update_cached_attributes.save!
    end

    tp = Tasks::Models::TaskPlan.arel_table
    Tasks::Models::TaskPlan.where(tp[:created_at].gt update_time).find_each do |task_plan|
      task_plan.update_attribute :wrq_count, task_plan.number_of_wrq_steps

      task_plan.update_gradable_step_counts!
    end
  end
end
