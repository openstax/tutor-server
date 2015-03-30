require 'rails_helper'

RSpec.describe TaskedExercise, :type => :model do
  it { is_expected.to belong_to(:recovery_tasked_exercise)
                        .dependent(:destroy) }

  it { is_expected.to validate_presence_of(:content) }

  it { is_expected.to delegate_method(:answers).to(:wrapper) }
  it { is_expected.to delegate_method(:correct_answer_ids).to(:wrapper) }
  it { is_expected.to delegate_method(:content_without_correctness)
                        .to(:wrapper) }

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

  it 'can return feedback depending on the selected answer' do
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    expect(tasked_exercise.feedback_html).to(
      eq tasked_exercise.answers[0][0]['feedback_html']
    )

    tasked_exercise.answer_id = tasked_exercise.answer_ids.last
    expect(tasked_exercise.feedback_html).to(
      eq tasked_exercise.answers[0][1]['feedback_html']
    )
  end

  it 'does not accept a multiple choice answer before a free response' do
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    expect(tasked_exercise).not_to be_valid
    expect(tasked_exercise.errors).to include :free_response

    tasked_exercise.free_response = 'abc'
    expect(tasked_exercise).to be_valid
  end

  it 'does not accept a multiple choice answer that is not listed' do
    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = SecureRandom.hex
    expect(tasked_exercise).not_to be_valid
    expect(tasked_exercise.errors).to include :answer_id

    tasked_exercise.answer_id = tasked_exercise.answer_ids.last
    expect(tasked_exercise).to be_valid
  end

  it 'cannot be updated after it is completed' do
    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    tasked_exercise.save!

    tasked_exercise.task_step.complete
    tasked_exercise.task_step.save!

    expect(tasked_exercise).not_to be_valid
    expect(tasked_exercise.reload).not_to be_valid
  end
end
