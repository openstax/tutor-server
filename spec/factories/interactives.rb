FactoryGirl.define do
  factory :interactive do
    resource
    title { Faker::Lorem.words(3) }
  end
end
