class FixContentExerciseAnswerOrders < ActiveRecord::Migration[4.2]
  def up
    Content::Models::Exercise.find_each do |exercise|
      answers = exercise.questions_hash.first['answers']
      exercise.questions_hash.first['answers'] = answers.sort_by{ |answer| answer['id'] }
      exercise.update_attribute(:content, exercise.content_hash.to_json)
    end
  end

  def down
  end
end
