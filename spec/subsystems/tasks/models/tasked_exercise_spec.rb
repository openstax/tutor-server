require 'rails_helper'

RSpec.describe Tasks::Models::TaskedExercise, :type => :model do
  it { is_expected.to validate_presence_of(:content) }

  it { is_expected.to delegate_method(:answers).to(:wrapper) }
  it { is_expected.to delegate_method(:correct_answer_ids).to(:wrapper) }
  it { is_expected.to delegate_method(:content_without_correctness)
                        .to(:wrapper) }

  let!(:hash) { OpenStax::Exercises::V1.fake_client.new_exercise_hash }
  let!(:content_exercise) { FactoryGirl.create :content_exercise,
                                               content: hash.to_json }
  let!(:tasked_exercise)  { FactoryGirl.create(:tasks_tasked_exercise,
                                               exercise: content_exercise) }

  it 'can return its wrapper' do
    expect(tasked_exercise.wrapper).to be_a(OpenStax::Exercises::V1::Exercise)

    expect(tasked_exercise.wrapper.url).to eq tasked_exercise.url
    expect(tasked_exercise.wrapper.content).to eq tasked_exercise.content
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

  it 'does not accept a multiple choice answer before a free response unless the free-response format is not present' do
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    expect(tasked_exercise).not_to be_valid
    expect(tasked_exercise.errors).to include :free_response

    tasked_exercise.free_response = 'abc'
    expect(tasked_exercise).to be_valid

    tasked_exercise.free_response = nil
    expect(tasked_exercise).not_to be_valid

    tasked_exercise.wrapper.instance_variable_set('@formats',
                                                  ['multiple-choice'])
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

  it "invalidates task's cache when updated" do
    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    expect { tasked_exercise.save! }.to change{ tasked_exercise.task_step.task.cache_key }
  end

  it 'records answers in exchange when the task_step is completed' do
    exchange_identifier = 42
    allow(tasked_exercise).to receive(:identifier).and_return(exchange_identifier)
    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    expect(OpenStax::Exchange).to receive(:record_multiple_choice_answer)
                                   .with(exchange_identifier,
                                         tasked_exercise.url,
                                         tasked_exercise.task_step.id.to_s,
                                         tasked_exercise.answer_ids.first)
    tasked_exercise.handle_task_step_completion!
  end
end
