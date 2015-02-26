require 'rails_helper'

RSpec.describe TaskedExercise, :type => :model do
  it { is_expected.to validate_presence_of(:content) }

  it { is_expected.to delegate_method(:title).to(:wrapper) }
  it { is_expected.to delegate_method(:answers).to(:wrapper) }
  it { is_expected.to delegate_method(:correct_answer_id).to(:wrapper) }
  it { is_expected.to delegate_method(:feedback_map).to(:wrapper) }
  it { is_expected.to delegate_method(:feedback_html).to(:wrapper) }

  let!(:hash) { OpenStax::Exercises::V1.fake_client.new_exercise_hash }
  let!(:tasked_exercise) { FactoryGirl.create(:tasked_exercise,
                                              content: hash.to_json) }

  it 'can return its wrapper' do
    expect(tasked_exercise.wrapper).to be_a(OpenStax::Exercises::V1::Exercise)

    expect(tasked_exercise.wrapper.url).to eq tasked_exercise.url
    expect(tasked_exercise.wrapper.content).to eq tasked_exercise.content
  end

  it 'automatically sets the url and title from the content' do
    tasked_exercise.url = nil
    expect(tasked_exercise.url).to(
      eq "http://exercises.openstax.org/exercises/#{hash[:uid]}"
    )

    tasked_exercise.title = nil
    expect(tasked_exercise.title).to eq hash['title']
  end
end
