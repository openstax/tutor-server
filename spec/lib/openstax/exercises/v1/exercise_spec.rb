require 'rails_helper'

RSpec.describe OpenStax::Exercises::V1::Exercise, :type => :external do
  let!(:title) { 'Some Title' }
  let!(:hash) { OpenStax::Exercises::V1.fake_client.new_exercise_hash
                                       .merge(title: title, tags: ['i-am-lo01', 'generic-tag']) }
  let!(:content) { hash.to_json }

  it 'returns attributes from the exercise JSON' do
    exercise = OpenStax::Exercises::V1::Exercise.new(content: content)
    expect(exercise.content).to eq content
    expect(exercise.url).to eq "#{OpenStax::Exercises::V1.server_url}/exercises/#{hash[:uid]}"
    expect(exercise.title).to eq title
    expect(exercise.question_answers[0].length).to eq 2
    expect(exercise.correct_question_answer_ids[0][0]).to eq exercise.question_answers[0][0]['id']
    expect(exercise.feedback_map[exercise.question_answers[0][0]['id']]).to eq 'Right!'
    expect(exercise.feedback_map[exercise.question_answers[0][1]['id']]).to eq 'Wrong!'
    expect(exercise.tags).to eq ['i-am-lo01', 'generic-tag']
    expect(exercise.los).to eq ['i-am-lo01']
    expect(exercise.is_multipart?).to eq false
  end
end
