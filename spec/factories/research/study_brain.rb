FactoryBot.define do
  factory :research_study_brain, class: '::Research::Models::StudyBrain' do
    association :cohort, factory: :research_cohort
    name { Faker::Company.name }
    code { "'BRAINZ!! MUST HAVE BRAINZ!'" }

    trait :update_student_task_step do
      type {  }
    end

    after(:create) do |brain, _|
      brain.add_instance_method
    end
  end

    factory :research_update_student_tasked,
            parent: :research_study_brain,
            class: 'Research::Models::UpdateStudentTasked' do
    end

    factory :research_display_student_task,
            parent: :research_study_brain,
            class: 'Research::Models::DisplayStudentTask' do
    end
end
