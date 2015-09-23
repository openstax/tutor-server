FactoryGirl.define do
  factory :user_profile_administrator, class: 'UserProfile::Models::Administrator' do
    association :profile, factory: :user_profile_profile
  end
end
