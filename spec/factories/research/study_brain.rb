FactoryBot.define do
  factory :research_study_brain, class: '::Research::Models::Brain' do
    association :study, factory: :research_study
    name { Faker::Company.name }
    code "'I AM ALIVE!'"
  end
end
