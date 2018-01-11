FactoryBot.define do
  factory :research_study, class: '::Research::Models::Study' do
    name { Faker::Name.name }
  end
end
