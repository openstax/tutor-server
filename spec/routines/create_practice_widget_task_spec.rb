require 'rails_helper'

RSpec.describe CreatePracticeWidgetTask, type: :routine do

  let(:role)          { FactoryGirl.create(:course_membership_student).role }
  let(:page)          { FactoryGirl.create :content_page }
  (1..5).each do |n|
    let!("exercise_#{n}".to_sym)   do
      FactoryGirl.create(:content_exercise, page: page).tap do |exercise|
        new_exercise_ids = page.practice_widget_pool.content_exercise_ids + [exercise.id]
        page.practice_widget_pool.update_attribute :content_exercise_ids, new_exercise_ids
      end
    end
  end
  let(:result)        do
    described_class.call role: role, exercise_source: :local, page_ids: [page.id]
  end
  let(:practice_task) { result.outputs.task }

  it 'creates tasks with 5 exercise steps and feedback immediately available' do
    expect(practice_task).to be_persisted
    expect(practice_task.task_steps.reload.size).to eq 5
    practice_task.task_steps.each{ |task_step| expect(task_step.exercise?).to eq true }
    expect(practice_task.feedback_available?).to be_truthy
  end

  it 'errors when there are not enough local exercises for the widget' do
    allow_any_instance_of(described_class).to receive(:get_local_exercises) { [] }
    expect(result.errors.first.code).to eq :no_exercises
  end

end
