# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :course do
    name "MyString"
    short_name "MyString"
    description "MyText"
    school_id 1
  end
end
