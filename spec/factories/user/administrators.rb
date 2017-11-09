FactoryBot.define do
  factory :user_administrator, class: 'User::Models::Administrator' do
    association :profile, factory: :user_profile
  end
end
