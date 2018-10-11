FactoryBot.define do
  factory :research_study_brain, class: '::Research::Models::StudyBrain' do
    association :study, factory: :research_study
    name { Faker::Company.name }
    code { "'BRAINZ!! MUST HAVE BRAINZ!'" }

    trait :update_student_task_step do
      type {  }
    end

    after(:create) do |brain, _|
      brain.add_instance_method
    end
  end

    factory :research_modified_tasked_for_update,
            parent: :research_study_brain,
            class: 'Research::Models::ModifiedTaskedForUpdate' do
    end

    factory :research_modified_task_for_display,
            parent: :research_study_brain,
            class: 'Research::Models::ModifiedTaskForDisplay' do
    end
end
