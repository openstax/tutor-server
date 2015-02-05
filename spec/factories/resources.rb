FactoryGirl.define do
  factory :resource do
    title { Faker::Lorem.words(3) }
    version { SecureRandom.hex }
    url { Faker::Internet.url }
  end
end
