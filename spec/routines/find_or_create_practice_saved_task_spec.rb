require 'rails_helper'
require_relative 'shared_examples_for_create_practice_task_routines'

RSpec.describe FindOrCreatePracticeSavedTask, type: :routine do
  before(:all) do
    DatabaseCleaner.start

    student = FactoryBot.create :course_membership_student
    @course = student.course
    @role = student.role

    @page = FactoryBot.create :content_page
    @ecosystem = @page.ecosystem

    exercises = 5.times.map { FactoryBot.create(:content_exercise, page: @page) }

    exercises.each do |exercise|
      tasked = FactoryBot.create(:tasks_tasked_exercise, :with_tasking, tasked_to: @role, exercise: exercise)
      FactoryBot.create(:tasks_practice_question, role: @role, exercise: exercise, tasked_exercise: tasked)
    end

    @course.course_ecosystems.delete_all :delete_all
    AddEcosystemToCourse[course: @course, ecosystem: @ecosystem]
  end

  before do
    @course.reload
    @role.reload
    @page.reload
    @ecosystem.reload
  end

  after(:all) { DatabaseCleaner.clean }

  let(:question) { @role.practice_questions.first }

  it 'creates a task with practice questions' do
    Preview::AnswerExercise.call task_step: question.tasked_exercise.task_step, is_correct: true, save: true
    allow_any_instance_of(Tasks::Models::Task).to receive(:auto_grading_feedback_on).and_return('answer')
    result = described_class.call(course: @course, role: @role, question_ids: [question.id])

    expect(result.outputs.task).not_to be_nil
    expect(result.outputs.task.task_steps.count).to eq(1)
    expect(result.errors).to be_empty
  end

  it 'filters out unavailable exercises' do
    result = described_class.call(course: @course, role: @role, question_ids: [question.id])
    expect(result.outputs.task).to be_nil
    expect(result.errors).not_to be_empty
  end
end
