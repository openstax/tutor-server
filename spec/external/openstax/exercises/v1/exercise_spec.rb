require 'rails_helper'

RSpec.describe OpenStax::Exercises::V1::Exercise do
  let!(:title) { 'Some Title' }
  let!(:hash) { OpenStax::Exercises::V1.fake_client.new_exercise_hash
                                                   .merge(title: title) }
  let!(:content) { hash.to_json }

  it 'returns attributes from the exercise JSON' do
    exercise = OpenStax::Exercises::V1::Exercise.new(content)
    expect(exercise.content).to eq content
    expect(exercise.url).to eq "http://exercises.openstax.org/exercises/#{hash[:uid]}"
    expect(exercise.title).to eq title
    expect(exercise.answers[0].length).to eq 2
    expect(exercise.correct_answer_ids[0]).to eq exercise.answers[0][0]['id']
    expect(exercise.feedback_html(exercise.answers[0][0]['id'])).to eq 'Right!'
    expect(exercise.feedback_html(exercise.answers[0][1]['id'])).to eq 'Wrong!'
  end
end
