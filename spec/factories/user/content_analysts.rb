FactoryBot.define do
  factory :user_content_analyst, class: 'User::Models::ContentAnalyst' do
    association :profile, factory: :user_profile
  end
end
