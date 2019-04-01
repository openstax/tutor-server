require 'rails_helper'

RSpec.describe Tasks::Models::TaskedExercise, type: :model do
  let(:content_exercise)    { FactoryBot.create :content_exercise }
  subject(:tasked_exercise) do
    FactoryBot.create :tasks_tasked_exercise, exercise: content_exercise
  end

  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_presence_of(:question_id) }
  it { is_expected.to validate_presence_of(:question_index) }
  it { is_expected.to validate_presence_of(:content) }
  it { is_expected.to validate_presence_of(:correct_answer_id) }
  it { is_expected.to validate_length_of(:free_response).is_at_most(10000) }

  it 'auto assigns the correct_answer_id on create' do
    expect(tasked_exercise.correct_answer_id).to(
      eq tasked_exercise.correct_question_answer_ids[0].first
    )
  end

  it 'does not accept a multiple choice answer before a free response' +
     ' unless the free-response format is not present' do
    tasked_exercise.answer_id = tasked_exercise.answer_ids.last
    expect(tasked_exercise).not_to be_valid
    expect(tasked_exercise.errors).to include :free_response

    tasked_exercise.free_response = 'abc'
    expect(tasked_exercise).to be_valid

    tasked_exercise.free_response = nil
    expect(tasked_exercise).not_to be_valid
    tasked_exercise.parser.questions_for_students.each{|q| q['formats'] = ['multiple-choice']}

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

    tasked_exercise.complete!

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

  describe '#content_preview' do
    let(:default_exercise_copy) { "Exercise step ##{tasked_exercise.id}" }
    let(:content_body) { 'exercise content' }
    let(:content) do
      { "questions" => [ {"stem_html" => content_body } ] }.to_json
    end

    it "parses the content for the content preview" do
      tasked_exercise.content = content
      expect(tasked_exercise.content_preview).to eq(content_body)
    end

    it "provides a default if the content preview is missing" do
      tasked_exercise.content = { blah: "preview missing" }.to_json
      expect(tasked_exercise.content_preview).to eq(default_exercise_copy)
    end
  end
end
