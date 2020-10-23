require 'rails_helper'

RSpec.describe Api::V1::PracticeQuestionRepresenter, type: :representer do
  it 'should represent a practice question' do
    question = FactoryBot.create(:tasks_practice_question)
    json = Api::V1::PracticeQuestionRepresenter.new(question).to_json

    expect(JSON.parse(json)).to include({
      id: question.id,
      tasked_exercise_id: question.tasked_exercise.id,
      exercise_id: question.exercise.id,
      available: question.available?,
    }.stringify_keys)
  end
end
