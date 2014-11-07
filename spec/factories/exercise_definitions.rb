# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :exercise_definition do
    klass_id 1
    url "MyString"
    content "MyText"
  end
end
