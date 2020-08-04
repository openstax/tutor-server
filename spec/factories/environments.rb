FactoryBot.define do
  factory :environment do
    name { SecureRandom.hex.to_s }
  end
end
