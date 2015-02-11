FactoryGirl.define do
  factory :book do
    resource
    title { Faker::Lorem.words(3) }
  end
end
