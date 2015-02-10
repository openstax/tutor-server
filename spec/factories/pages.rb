FactoryGirl.define do
  factory :page do
    resource
    book
    title { Faker::Lorem.words(3) }
    cnx_id { SecureRandom.hex }
    version { SecureRandom.hex }
  end
end
