require 'rails_helper'

RSpec.describe Tasks::Models::TaskedExercise, type: :model do
  let(:content_exercise) { FactoryGirl.create :content_exercise }
  subject(:tasked_exercise)  { FactoryGirl.create(:tasks_tasked_exercise,
                                                  exercise: content_exercise) }

  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:correct_answer_id) }
  it { is_expected.to validate_length_of(:free_response).is_at_most(10000) }

  it 'auto assigns the correct_answer_id on create' do
    expect(tasked_exercise.correct_answer_id).to(
      eq tasked_exercise.correct_question_answer_ids[0].first
    )
  end

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
    tasked_exercise.task_step.task.feedback_at = nil
    tasked_exercise.task_step.task.save!

    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    tasked_exercise.save!

    expect(tasked_exercise.reload).to be_valid

    tasked_exercise.task_step.complete
    tasked_exercise.task_step.save!

    expect(tasked_exercise.reload).not_to be_valid

    tasked_exercise.task_step.task.feedback_at = Time.current.yesterday
    tasked_exercise.task_step.task.save!

    expect(tasked_exercise.reload).not_to be_valid

    tasked_exercise.task_step.task.feedback_at = Time.current.tomorrow
    tasked_exercise.task_step.task.save!

    expect(tasked_exercise.reload).to be_valid
  end

  it "invalidates task's cache when updated" do
    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    expect { tasked_exercise.save! }.to change{ tasked_exercise.task_step.task.cache_key }
  end
end
