FactoryBot.define do
  factory :lti_user, class: '::Lti::User' do
    association :profile,  factory: :user_profile
    association :platform, factory: :lti_platform

    uid { SecureRandom.hex }
  end
end
