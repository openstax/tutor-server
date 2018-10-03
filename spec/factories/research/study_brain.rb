FactoryBot.define do
  factory :research_study_brain, class: '::Research::Models::Brain' do
    association :cohort, factory: :research_cohort
    name { Faker::Company.name }
    domain { :student_task } # we have only one currently
    code { "'BRAINZ!! MUST HAVE BRAINZ!'" }
  end
end
