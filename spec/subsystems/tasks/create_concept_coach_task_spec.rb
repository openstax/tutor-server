require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::CreateConceptCoachTask, type: :routine do
  let(:user)             { FactoryBot.create :user }
  let(:period)           { FactoryBot.create :course_membership_period }
  let(:role)             { AddUserAsPeriodStudent[user: user, period: period] }
  let(:page_model)       { FactoryBot.create :content_page }
  let(:page)             { Content::Page.new(strategy: page_model.wrap) }

  let(:exercise_model_1) { FactoryBot.create :content_exercise, page: page_model }
  let(:exercise_model_2) { FactoryBot.create :content_exercise, page: page_model }
  let(:exercise_model_3) { FactoryBot.create :content_exercise, page: page_model }
  let(:exercise_model_4) { FactoryBot.create :content_exercise, page: page_model }
  let(:exercise_model_5) { FactoryBot.create :content_exercise, page: page_model }

  let(:exercises)        do
    [exercise_model_5, exercise_model_4, exercise_model_3,
     exercise_model_2, exercise_model_1].map do |exercise_model|
      Content::Exercise.new(strategy: exercise_model.wrap)
    end
  end

  let(:group_types) do
    [:core_group, :core_group, :core_group, :spaced_practice_group, :spaced_practice_group]
  end

  it 'creates a task containing the given exercises in the proper order' do
    task = nil
    expect{ task = described_class[role: role, page: page, exercises: exercises,
                                   group_types: group_types] }.to(
      change{ Tasks::Models::Task.count }.by(1)
    )
    expect(task.concept_coach?).to eq true
    expect(task.tasked_exercises.map(&:content_exercise_id)).to eq exercises.map(&:id)
    expect(task.task_steps.map(&:group_type)).to eq group_types.map(&:to_s)
  end

  it 'creates a ConceptCoachTask object' do
    task = nil
    expect{ task = described_class[role: role, page: page, exercises: exercises,
                                   group_types: group_types] }.to(
      change{ Tasks::Models::ConceptCoachTask.count }.by(1)
    )
    cc_task = Tasks::Models::ConceptCoachTask.order(:created_at).last
    expect(cc_task.page).to eq page_model
    expect(cc_task.role).to eq role
    expect(cc_task.task).to eq task
    expect(task.taskings.first.role).to eq role
  end

  it 'errors if the course has ended' do
    current_time = Time.current
    course = role.student.course
    course.starts_at = current_time.last_month
    course.ends_at = current_time.yesterday
    course.save!

    result = nil
    expect do
      result = described_class.call(role: role, page: page, exercises: exercises,
                                    group_types: group_types)
    end.not_to change{ Tasks::Models::ConceptCoachTask.count }
    expect(result.errors.first.code).to eq :course_ended
  end
end
