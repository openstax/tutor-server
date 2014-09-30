# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :resource do
    url "MyString"
    url_is_permalink false
    content "MyText"
  end
end
