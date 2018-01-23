FactoryBot.define do
  factory :user_researcher, class: 'User::Models::Researcher' do
    association :profile, factory: :user_profile
  end
end
