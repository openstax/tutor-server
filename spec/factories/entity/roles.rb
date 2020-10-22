FactoryBot.define do
  factory :entity_role, class: '::Entity::Role' do
    association :profile, factory: :user_profile
    association :practice_questions, factory: :tasks_practice_question
  end
end
