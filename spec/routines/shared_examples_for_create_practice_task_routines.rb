require 'rails_helper'

RSpec.shared_examples 'a routine that creates practice tasks' do |result_proc|
  before(:all) do
    DatabaseCleaner.start

    student = FactoryBot.create :course_membership_student
    @course = student.course
    @role = student.role

    @page = FactoryBot.create :content_page
    @ecosystem = @page.ecosystem

    exercises = 5.times.map { FactoryBot.create(:content_exercise, page: @page) }

    new_exercise_ids = @page.practice_widget_exercise_ids + exercises.map(&:id)
    @page.update_attribute :practice_widget_exercise_ids, new_exercise_ids

    @course.course_ecosystems.delete_all :delete_all
    AddEcosystemToCourse[course: @course, ecosystem: @ecosystem]
  end

  after(:all) { DatabaseCleaner.clean }

  before do
    @course.reload
    @role.reload
    @page.reload
    @ecosystem.reload
  end

  let(:result)        { instance_exec &result_proc }
  let(:practice_task) { result.outputs.task }
  let(:errors)        { result.errors }

  it 'errors when the course has ended' do
    current_time = Time.current
    @course.starts_at = current_time.last_month
    @course.ends_at = current_time.yesterday
    @course.save!

    expect(errors.first.code).to eq :course_ended
  end

  it 'does not clear incomplete steps from previous practice widgets' do
    expect(errors).to be_empty

    Preview::AnswerExercise[task_step: practice_task.task_steps.first, is_correct: false]
    result_2 = instance_exec &result_proc
    expect(result_2.errors).to be_empty
    practice_task_2 = result_2.outputs.task
    expect(practice_task_2).to be_persisted

    expect(practice_task.task_steps.reload.size).to eq 5
  end

  it 'creates tasks with 5 exercise steps and feedback immediately available' do
    expect(errors).to be_empty
    expect(practice_task).to be_persisted
    expect(practice_task.task_steps.size).to eq 5
    practice_task.task_steps.each { |task_step| expect(task_step.exercise?).to eq true }
    expect(practice_task.auto_grading_feedback_available?).to eq true
    expect(practice_task.manual_grading_feedback_available?).to eq false
  end
end
