# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :student do
    klass_id 1
    section_id 1
    user_id 1
    level 1
    has_dropped false
    student_custom_identifier "MyString"
    educator_custom_identifier "MyString"
    random_education_identifier "MyString"
  end
end
