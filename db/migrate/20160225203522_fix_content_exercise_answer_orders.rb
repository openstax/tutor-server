class FixContentExerciseAnswerOrders < ActiveRecord::Migration
  def up
    Content::Models::Exercise.find_each do |exercise|
      content_hash = JSON.parse(exercise.content)
      answers = content_hash['questions'].first['answers']
      content_hash['questions'].first['answers'] = answers.sort_by{ |answer| answer['id'] }
      exercise.update_attribute(:content, content_hash.to_json)
    end
  end

  def down
  end
end
