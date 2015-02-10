FactoryGirl.define do
  factory :exercise do
    resource
    title { Faker::Lorem.words(3) }
  end
end
