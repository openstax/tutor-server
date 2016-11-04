FactoryGirl.define do
  factory :tasks_course_assistant, class: '::Tasks::Models::CourseAssistant' do
    association :course, factory: :course_profile_course
    association :assistant, factory: :tasks_assistant
    tasks_task_plan_type 'dummy'
  end
end
