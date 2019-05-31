class AddCorrectAnswerIdToTasksTaskedExercises < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks_tasked_exercises, :correct_answer_id, :string

    Tasks::Models::TaskedExercise.unscoped.lock.find_each do |te|
      te.update_column(:correct_answer_id, te.correct_question_answer_ids[0].first)
    end

    change_column_null :tasks_tasked_exercises, :correct_answer_id, false
  end
end
