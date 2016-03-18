class FixTaskedExerciseAnswerOrders < ActiveRecord::Migration
  def up
    Tasks::Models::TaskedExercise.preload(:exercise).find_each do |tasked_exercise|
      tasked_exercise.update_attribute(:content, tasked_exercise.exercise.content)
    end
  end

  def down
  end
end
