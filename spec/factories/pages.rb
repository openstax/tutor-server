FactoryGirl.define do
  factory :page do
    resource
    book
    title { Faker::Lorem.words(3) }
  end
end
