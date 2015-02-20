require 'rails_helper'

RSpec.describe OpenStax::Exercises::V1::Exercise do
  let!(:url) { 'http://dum.my/exercises/1' }
  let!(:title) { 'Some Title' }
  let!(:content) { OpenStax::Exercises::V1.fake_client.new_exercise_hash
                                          .merge(title: title).to_json }

  it 'returns attributes from the exercise JSON' do
    exercise = OpenStax::Exercises::V1::Exercise.new(url, content)
    expect(exercise.url).to eq url
    expect(exercise.content).to eq content
    expect(exercise.title).to eq title
    expect(exercise.answers.length).to eq 2
    expect(exercise.correct_answer_id).to eq exercise.answers.first['id']
    expect(exercise.feedback_html(exercise.answers.first['id'])).to eq 'Right!'
    expect(exercise.feedback_html(exercise.answers.last['id'])).to eq 'Wrong!'
  end
end
