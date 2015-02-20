require 'rails_helper'

RSpec.describe TaskedExercise, :type => :model do
  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_presence_of(:content) }

  it { is_expected.to delegate_method(:title).to(:wrapper) }
  it { is_expected.to delegate_method(:answers).to(:wrapper) }
  it { is_expected.to delegate_method(:correct_answer_id).to(:wrapper) }
  it { is_expected.to delegate_method(:feedback_map).to(:wrapper) }
  it { is_expected.to delegate_method(:feedback_html).to(:wrapper) }

  it 'can return its wrapper' do
    tasked_exercise = FactoryGirl.create(
      :tasked_exercise,
      content: OpenStax::Exercises::V1.fake_client.new_exercise_hash.to_json
    )

    expect(tasked_exercise.wrapper).to be_a(OpenStax::Exercises::V1::Exercise)

    expect(tasked_exercise.wrapper.url).to eq tasked_exercise.url
    expect(tasked_exercise.wrapper.content).to eq tasked_exercise.content
  end
end
