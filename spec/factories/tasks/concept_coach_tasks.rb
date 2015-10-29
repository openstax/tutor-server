FactoryGirl.define do
  factory :tasks_concept_coach_task do
    association :task, factory: :entity_task
    association :page, factory: :content_page
  end
end
