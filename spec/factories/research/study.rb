FactoryBot.define do
  factory :research_study, class: '::Research::Models::Study' do
    name { Faker::Name.name }
    trait :active do
      last_activated_at { Time.now }
    end
  end
end
