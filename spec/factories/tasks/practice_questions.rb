FactoryBot.define do
  factory :tasks_practice_question, class: '::Tasks::Models::PracticeQuestion' do
    association :role, factory: :entity_role
    association :tasked_exercise, factory: :tasks_tasked_exercise
    association :exercise, factory: :content_exercise
  end
end
