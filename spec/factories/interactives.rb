FactoryGirl.define do
  factory :interactive do
    url { Faker::Internet.url }
    title { Faker::Lorem.words(3) }
  end
end
