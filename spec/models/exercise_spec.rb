require 'rails_helper'

RSpec.describe Exercise, :type => :model do
  it { is_expected.to have_many(:exercise_topics).dependent(:destroy) }

  it { is_expected.to delegate_method(:title).to(:wrapper) }
  it { is_expected.to delegate_method(:answers).to(:wrapper) }
  it { is_expected.to delegate_method(:correct_answer_id).to(:wrapper) }
  it { is_expected.to delegate_method(:feedback_map).to(:wrapper) }
  it { is_expected.to delegate_method(:feedback_html).to(:wrapper) }

  it 'can return its wrapper' do
    exercise = FactoryGirl.create(
      :exercise,
      content: OpenStax::Exercises::V1.fake_client.new_exercise_hash.to_json
    )

    expect(exercise.wrapper).to be_a(OpenStax::Exercises::V1::Exercise)

    expect(exercise.wrapper.url).to eq exercise.url
    expect(exercise.wrapper.content).to eq exercise.content
  end
end
