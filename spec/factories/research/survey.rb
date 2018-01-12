FactoryBot.define do
  factory :research_survey, class: '::Research::Models::ToolConsumer' do
    association :survey_plan, factory: :research_study
    association :student, factory: :course_membership_student

    trait :completed do
      completed_at { Time.now }
    end

    trait :hidden do
      hidden_at { Time.now }
    end
  end
end
