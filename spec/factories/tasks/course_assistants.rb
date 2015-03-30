FactoryGirl.define do
  factory :tasks_course_assistant, class: '::Tasks::Models::CourseAssistant' do
    association :course, factory: :entity_course
    association :assistant, factory: :tasks_assistant
    task_plan_type 'dummy'
  end
end
