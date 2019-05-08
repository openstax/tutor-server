FactoryBot.define do
  factory :entity_role, class: '::Entity::Role' do
    association :profile, factory: :user_profile
  end
end
