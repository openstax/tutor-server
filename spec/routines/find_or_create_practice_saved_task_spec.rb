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
      FactoryBot.create :tasks_practice_question, role: @role, exercise: exercise
    end

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

  let(:question_id)   { @role.practice_questions.first.id }

  it 'creates a task with practice questions' do
    allow_any_instance_of(Tasks::Models::PracticeQuestion).to receive(:available?).and_return(true)
    result = described_class.call(course: @course, role: @role, question_ids: [question_id])
    expect(result.outputs.task).not_to be_nil
    expect(result.outputs.task.task_steps.count).to eq(1)
    expect(result.errors).to be_empty
  end

  it 'filters out unavailable exercises' do
    result = described_class.call(course: @course, role: @role, question_ids: [question_id])
    expect(result.outputs.task).to be_nil
    expect(result.errors).not_to be_empty
  end
end
