FactoryBot.define do
  factory :research_survey, class: '::Research::Models::Survey' do
    association :survey_plan, factory: :research_survey_plan
    association :student, factory: :course_membership_student

    trait :completed do
      completed_at { Time.now }
    end

    trait :hidden do
      hidden_at { Time.now }
    end
  end
end
