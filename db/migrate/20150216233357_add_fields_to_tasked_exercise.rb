class AddFieldsToTaskedExercise < ActiveRecord::Migration
  def change
    add_column :tasked_exercises, :feedback_html, :text
    add_column :tasked_exercises, :correct_answer_id, :string
    add_column :tasked_exercises, :answer_id, :string
    add_column :tasked_exercises, :free_response, :text
  end
end
