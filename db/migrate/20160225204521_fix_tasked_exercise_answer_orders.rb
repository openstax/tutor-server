class FixTaskedExerciseAnswerOrders < ActiveRecord::Migration
  def up
    Tasks::Models::TaskedExercise.update_all('content = content_exercises.content FROM content_exercises WHERE tasks_tasked_exercises.content_exercise_id = content_exercises.id')
  end

  def down
  end
end
