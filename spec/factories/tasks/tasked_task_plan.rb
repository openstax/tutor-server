# To allow use in the development environment
if Rails.env.development?
  require_relative '../../vcr_helper'
  require_relative '../../support/fake_exercise_uuids'
end

FactoryBot.define do

  factory :tasked_task_plan, parent: :tasks_task_plan do
    type      { 'reading' }

    assistant do
      Tasks::Models::Assistant.find_by(
        code_class_name: 'Tasks::Assistants::IReadingAssistant'
      ) || FactoryBot.create(
        :tasks_assistant, code_class_name: 'Tasks::Assistants::IReadingAssistant'
      )
    end

    transient do
      number_of_students { 10 }
    end


    ecosystem do
      PopulateMiniEcosystem.generate_mini_ecosystem
    end

    course    { FactoryBot.build :course_profile_course, offering: nil }

    settings { { page_ids: [ ecosystem.pages.last.id.to_s ] } }

    after(:build) do |task_plan, evaluator|
      course = task_plan.course
      period = course.periods.first || FactoryBot.create(
        :course_membership_period, course: course
      )

      evaluator.number_of_students.times do
        AddUserAsPeriodStudent.call(user: create(:user_profile), period: period)
      end

      task_plan.tasking_plans = [build(:tasks_tasking_plan, task_plan: task_plan, target: period)]
    end

    after(:create) { |task_plan, evaluator| DistributeTasks.call(task_plan: task_plan) }
  end
end
