FactoryGirl.define do
  factory :page do
    url { Faker::Internet.url }
    book
    title { Faker::Lorem.words(3) }
  end
end
