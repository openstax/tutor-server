FactoryGirl.define do
  factory :resource do
    url { Faker::Internet.url }
  end
end
