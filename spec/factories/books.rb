FactoryGirl.define do
  factory :book do
    title { Faker::Lorem.words(3) }
    cnx_id { SecureRandom.hex }
    version { SecureRandom.hex }
  end
end
