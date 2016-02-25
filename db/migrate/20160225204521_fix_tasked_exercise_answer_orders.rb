class FixTaskedExerciseAnswerOrders < ActiveRecord::Migration
  def up
    Tasks::Models::TaskedExercise.find_each do |tasked_exercise|
      content_hash = JSON.parse(tasked_exercise.content)
      answers = content_hash['questions'].first['answers']
      content_hash['questions'].first['answers'] = answers.sort_by{ |answer| answer['id'] }
      tasked_exercise.update_attribute(:content, content_hash.to_json)
    end
  end

  def down
  end
end
