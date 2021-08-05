class AddAllowAutoGradedMultipleAttemptsToTasksGradingTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_grading_templates,
               :allow_auto_graded_multiple_attempts,
               :boolean,
               default: false,
               null: false
  end
end
