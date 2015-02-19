FactoryGirl.define do
  factory :book do
    title { Faker::Lorem.words(3) }
  end
end
