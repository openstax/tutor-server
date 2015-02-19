FactoryGirl.define do
  factory :exercise do
    url { Faker::Internet.url }
    title { Faker::Lorem.words(3) }
  end
end
