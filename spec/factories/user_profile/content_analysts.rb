FactoryGirl.define do
  factory :user_profile_content_analyst, class: 'UserProfile::Models::ContentAnalyst' do
    association :profile, factory: :user_profile_profile
  end
end
