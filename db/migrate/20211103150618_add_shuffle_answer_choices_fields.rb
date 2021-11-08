class AddShuffleAnswerChoicesFields < ActiveRecord::Migration[5.2]
  def change
    add_column :tasks_grading_templates, :shuffle_answer_choices, :boolean, default: false, null: false
  end
end
