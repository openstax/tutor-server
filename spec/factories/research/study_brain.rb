FactoryBot.define do
  factory :research_study_brain, class: '::Research::Models::Brain' do
    association :cohort, factory: :research_cohort
    name { Faker::Company.name }
    code "'I AM ALIVE!'"
  end
end
