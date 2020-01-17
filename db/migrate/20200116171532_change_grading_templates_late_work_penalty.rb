class ChangeGradingTemplatesLateWorkPenalty < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_grading_templates,         :late_work_penalty_applied,   :integer
    rename_column :tasks_grading_templates,      :late_work_immediate_penalty, :late_work_penalty
    remove_column :tasks_grading_templates,      :late_work_per_day_penalty,   :integer
    change_column_null :tasks_grading_templates, :late_work_penalty_applied,   false, 2
  end
end
