# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :course_manager do
    course
    user
  end
end
