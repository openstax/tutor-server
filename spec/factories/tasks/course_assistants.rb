FactoryGirl.define do
  factory :tasks_course_assistant do
    association :course, factory: :course
    association :assistant, factory: :tasks_assistant
  end
end
