require 'rails_helper'

RSpec.describe ResetPracticeWidget, type: :routine do

  let(:student)       { FactoryGirl.create :course_membership_student }
  let(:course)        { student.course }
  let(:role)          { student.role }

  let(:page)          { FactoryGirl.create :content_page }

  let(:ecosystem)     { Content::Ecosystem.new strategy: page.ecosystem.wrap }

  (1..5).each do |n|
    let!("exercise_#{n}".to_sym)   do
      FactoryGirl.create(:content_exercise, page: page).tap do |exercise|
        new_exercise_ids = page.practice_widget_pool.content_exercise_ids + [exercise.id]
        page.practice_widget_pool.update_attribute :content_exercise_ids, new_exercise_ids
      end
    end
  end

  let(:result)        do
    described_class.call role: role, page_ids: [page.id]
  end

  let(:practice_task) { result.outputs.task }

  before              do
    AddEcosystemToCourse[course: course, ecosystem: ecosystem]
  end

  it 'returns results from CreatePracticeWidgetTask' do
    expect(practice_task).to be_persisted
    expect(practice_task.task_steps.reload.size).to eq 5
    practice_task.task_steps.each{ |task_step| expect(task_step.exercise?).to eq true }
    expect(practice_task.feedback_available?).to be_truthy
  end

  it 'clears incomplete steps from previous practice widgets' do
    Preview::AnswerExercise[task_step: practice_task.task_steps.first, is_correct: false]
    practice_task_2 = described_class[role: role, page_ids: [page.id]]
    expect(practice_task_2).to be_persisted
    expect(practice_task.task_steps.reload.size).to eq 1
  end

  it 'errors when the course has ended' do
    current_time = Time.current
    course = role.student.course
    course.starts_at = current_time.last_month
    course.ends_at = current_time.yesterday
    course.save!

    result = described_class.call(role: role, page_ids: [])
    expect(result.errors.first.code).to eq :course_ended
  end

end
