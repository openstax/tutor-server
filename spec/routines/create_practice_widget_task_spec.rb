require 'rails_helper'

RSpec.describe CreatePracticeWidgetTask, type: :routine do

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

  it 'creates tasks with 5 exercise steps and feedback immediately available' do
    expect(practice_task).to be_persisted
    expect(practice_task.task_steps.reload.size).to eq 5
    practice_task.task_steps.each{ |task_step| expect(task_step.exercise?).to eq true }
    expect(practice_task.feedback_available?).to be_truthy
  end

  it 'errors when there are not enough local exercises for the widget' do
    expect(OpenStax::Biglearn::Api).to receive(:fetch_assignment_pes).and_return([])
    expect(result.errors.first.code).to eq :no_exercises
  end

end
