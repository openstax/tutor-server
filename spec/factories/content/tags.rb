FactoryBot.define do
  factory :content_tag, class: '::Content::Models::Tag' do
    association :ecosystem, factory: :content_ecosystem

    value       { SecureRandom.hex }
    name        { Faker::Lorem.word }
    description { Faker::Lorem.paragraph }
    tag_type    { :generic }
  end
end
