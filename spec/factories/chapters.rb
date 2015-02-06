FactoryGirl.define do
  factory :chapter do
    book
    title { Faker::Lorem.words(3) }
  end
end
