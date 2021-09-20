FactoryBot.define do
  factory :lti_user, class: '::Lti::User' do
    association :profile,  factory: :user_profile
    association :platform, factory: :lti_platform

    uid                  { SecureRandom.hex }
    last_message_type    { 'LtiResourceLinkRequest' }
    last_context_id      { SecureRandom.hex }
    last_is_instructor   { [ true, false ].sample }
    last_is_student      { [ true, false ].sample }
    last_target_link_uri { '/' }
  end
end
