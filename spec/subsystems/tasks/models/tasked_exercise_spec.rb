require 'rails_helper'

RSpec.describe Tasks::Models::TaskedExercise, type: :model do
  let(:content_exercise)    { FactoryBot.create :content_exercise }
  subject(:tasked_exercise) do
    FactoryBot.create :tasks_tasked_exercise, exercise: content_exercise
  end

  it { is_expected.to validate_presence_of(:url) }
  it { is_expected.to validate_presence_of(:question_id) }
  it { is_expected.to validate_presence_of(:question_index) }
  it { is_expected.to validate_presence_of(:correct_answer_id) }
  it { is_expected.to validate_length_of(:free_response).is_at_most(10000) }
  it { is_expected.to validate_numericality_of(:grader_points).is_greater_than_or_equal_to(0.0) }

  it 'auto assigns the correct_answer_id on create' do
    expect(tasked_exercise.correct_answer_id).to(
      eq tasked_exercise.correct_question_answer_ids[0].first
    )
  end

  it 'does not accept a multiple choice answer before a free response' +
     ' unless the free-response format is not present' do
    expect(tasked_exercise.answer_id).not_to eq tasked_exercise.answer_ids.first
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first

    expect(tasked_exercise).not_to be_valid
    expect(tasked_exercise.errors).to include :free_response

    tasked_exercise.free_response = 'abc'
    expect(tasked_exercise).to be_valid

    tasked_exercise.free_response = nil
    expect(tasked_exercise).not_to be_valid
    tasked_exercise.parser.questions_for_students.each{|q| q['formats'] = ['multiple-choice']}

    expect(tasked_exercise).to be_valid
  end

  it 'requires answer_id if the exercise has answers' do
    tasked_exercise.answer_id = 1
    expect(tasked_exercise).not_to have_answer_missing
    tasked_exercise.answer_id = nil
    expect(tasked_exercise).to have_answer_missing
    tasked_exercise.answer_ids.clear # simulate a WRM question with no answers
    expect(tasked_exercise).not_to have_answer_missing
  end

  it 'does not accept a blank free response if the free-response format is present' do
    tasked_exercise.free_response = ' '
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
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

  it 'cannot have answer or free response updated after feedback is available' do
    grading_template = tasked_exercise.task_step.task.task_plan.grading_template
    grading_template.update_column :auto_grading_feedback_on, :answer

    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    tasked_exercise.save!

    expect(tasked_exercise.reload).to be_valid

    tasked_exercise.complete!

    expect(tasked_exercise.reload).to be_valid

    tasked_exercise.answer_id = tasked_exercise.answer_ids.last
    expect(tasked_exercise).not_to be_valid

    expect(tasked_exercise.reload).to be_valid
    tasked_exercise.free_response = 'some new thing'
    expect(tasked_exercise).not_to be_valid

    grading_template.update_column :auto_grading_feedback_on, :due

    expect(tasked_exercise.reload).to be_valid
    tasked_exercise.answer_id = tasked_exercise.answer_ids.last
    expect(tasked_exercise).to be_valid

    expect(tasked_exercise.reload).to be_valid
    tasked_exercise.free_response = 'some new thing'
    expect(tasked_exercise).to be_valid
  end

  it 'cannot be answered after graded' do
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    tasked_exercise.free_response = 'abc'
    expect(tasked_exercise.was_manually_graded?).to eq false
    expect(tasked_exercise.task_step.can_be_updated?).to eq true
    tasked_exercise.save!

    tasked_exercise.last_graded_at = Time.current
    tasked_exercise.grader_points = 0.0
    expect(tasked_exercise.was_manually_graded?).to eq true
    expect(tasked_exercise.task_step.can_be_updated?).to eq false
    tasked_exercise.save!

    tasked_exercise.answer_id = tasked_exercise.answer_ids.last
    tasked_exercise.free_response = 'def'
    expect(tasked_exercise).not_to be_valid
  end

  it "invalidates task's cache when updated" do
    tasked_exercise.free_response = 'abc'
    tasked_exercise.answer_id = tasked_exercise.answer_ids.first
    expect { tasked_exercise.save! }.to change { tasked_exercise.task_step.task.cache_version }
  end

  it 'returns 0.0 grader_points when unattempted, past-due, ungraded and course setting set' do
    expect(tasked_exercise.grader_points).to be_nil

    tasked_exercise.answer_ids = []

    task = tasked_exercise.task_step.task
    task.due_at = task.time_zone.to_tz.now - 1.minute
    task.course.past_due_unattempted_ungraded_wrq_are_zero = true

    expect(tasked_exercise.grader_points).to eq 0.0
  end

  context '#content_preview' do
    let(:default_exercise_copy) { "Exercise step ##{tasked_exercise.id}" }
    let(:content_body) { 'exercise content' }
    let(:content) do
      {
        questions: [
          {
            id: '1',
            stem_html: content_body,
            answers: [
              { id: '1', correctness: 1.0 }
            ]
          }
        ]
      }.to_json
    end

    it "parses the content for the content preview" do
      content_exercise.update_attribute :content, content
      expect(tasked_exercise.content_preview).to eq(content_body)
    end
  end

  it 'returns the correct available_points' do
    tasked_exercise.task_step.task.homework!

    # Full reload, including reloading our custom instance variables
    id = tasked_exercise.id
    tasked_exercise = described_class.find id
    expect(tasked_exercise.available_points).to eq 1.0

    task_plan = tasked_exercise.task_step.task.task_plan
    task_plan.type = 'homework'
    task_plan.settings = {
      exercises: [ { id: tasked_exercise.content_exercise_id, points: [ 2.0 ] } ]
    }
    task_plan.save validate: false

    id = tasked_exercise.id
    tasked_exercise = described_class.find id
    expect(tasked_exercise.available_points).to eq 2.0
  end
end
