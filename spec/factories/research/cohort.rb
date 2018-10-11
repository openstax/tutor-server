FactoryBot.define do
  factory :research_cohort, class: '::Research::Models::Cohort' do
    name { Faker::Company.name }
    association :study, factory: :research_study
  end
end
