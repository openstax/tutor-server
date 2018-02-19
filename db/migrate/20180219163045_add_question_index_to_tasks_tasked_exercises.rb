class AddQuestionIndexToTasksTaskedExercises < ActiveRecord::Migration
  def change
    add_column :tasks_tasked_exercises, :question_index, :integer

    reversible do |dir|
      dir.up do
        Tasks::Models::TaskedExercise
          .select([ :id, :question_id, '"content_exercises"."content"' ])
          .joins(:exercise)
          .find_in_batches do |tasked_exercises|
            tasked_exercise_ids = tasked_exercises.map(&:id)

            cases = tasked_exercises.map do |tasked_exercise|
              question_index = tasked_exercise.questions.index do |question|
                question['id'] == tasked_exercise.question_id
              end

              [ tasked_exercise.id, question_index ]
            end
            case_sql = cases.map { |id, index| "WHEN #{id} THEN #{index}" }.join(' ')
            update_sql = "\"question_index\" = CASE \"id\" #{case_sql} END"

            Tasks::Models::TaskedExercise.where(id: tasked_exercise_ids).update_all(update_sql)
        end
      end
    end

    change_column_null :tasks_tasked_exercises, :question_index, false
  end
end
