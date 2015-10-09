require 'rails_helper'

RSpec.describe Tasks::Models::TaskedExercise, type: :model do
  it { is_expected.to validate_presence_of(:content) }

  let!(:hash) { OpenStax::Exercises::V1.fake_client.new_exercise_hash }
  let!(:content_exercise) { FactoryGirl.create :content_exercise,
                                               content: hash.to_json }
  let!(:tasked_exercise)  { FactoryGirl.create(:tasks_tasked_exercise,
                                               exercise: content_exercise) }

  it 'does not accept a multiple choice answer before a free response unless the free-response format is not present' do
    tasked_exercise.answer_id = tasked_exercise.answer_ids.last
    expect(tasked_exercise).not_to be_valid
    expect(tasked_exercise.errors).to include :free_response

    tasked_exercise.free_response = 'abc'
    expect(tasked_exercise).to be_valid

    tasked_exercise.free_response = nil
    expect(tasked_exercise).not_to be_valid

    tasked_exercise.parser.instance_variable_set('@question_formats', ['multiple-choice'])
    expect(tasked_exercise).to be_valid
  end

  it 'does not accept a blank free response if the free-response format is present' do
    tasked_exercise.free_response = ' '
    expect(tasked_exercise).not_to be_valid
  end

  it 'does not accept a multiple choice answer that is not listed' do
    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = SecureRandom.hex
    expect(tasked_exercise).not_to be_valid
    expect(tasked_exercise.errors).to include :answer_id

    tasked_exercise.answer_id = tasked_exercise.answer_ids.last
    expect(tasked_exercise).to be_valid
  end

  it 'cannot be updated after the step is completed and feedback is available' do
    tasked_exercise.task_step.task.feedback_at = Time.now
    tasked_exercise.task_step.task.save!

    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    tasked_exercise.save!

    expect(tasked_exercise.reload).to be_valid

    tasked_exercise.task_step.complete
    tasked_exercise.task_step.save!

    expect(tasked_exercise.reload).not_to be_valid

    tasked_exercise.task_step.task.feedback_at = nil
    tasked_exercise.task_step.task.save!

    expect(tasked_exercise.reload).to be_valid

    tasked_exercise.task_step.task.feedback_at = Time.now
    tasked_exercise.task_step.task.save!

    expect(tasked_exercise.reload).not_to be_valid
  end

  it "invalidates task's cache when updated" do
    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    expect { tasked_exercise.save! }.to change{ tasked_exercise.task_step.task.cache_key }
  end

  it 'calls SendTaskedExerciseAnswerToExchange when completed' do
    expect(SendTaskedExerciseAnswerToExchange).to(
      receive(:perform_later).with(tasked_exercise: tasked_exercise)
    )
    tasked_exercise.handle_task_step_completion!
  end
end
