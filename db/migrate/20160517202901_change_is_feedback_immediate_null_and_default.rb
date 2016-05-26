class ChangeIsFeedbackImmediateNullAndDefault < ActiveRecord::Migration
  def up
    Tasks::Models::TaskPlan.where(type: 'homework', is_feedback_immediate: nil)
                           .update_all(is_feedback_immediate: false)

    Tasks::Models::TaskPlan.where(is_feedback_immediate: nil)
                           .update_all(is_feedback_immediate: true)

    change_column_default :tasks_task_plans, :is_feedback_immediate, true
    change_column_null :tasks_task_plans, :is_feedback_immediate, false
  end

  def down
    change_column_null :tasks_task_plans, :is_feedback_immediate, true
    change_column_default :tasks_task_plans, :is_feedback_immediate, nil
  end
end
