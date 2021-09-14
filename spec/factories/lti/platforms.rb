FactoryBot.define do
  factory :lti_platform, class: '::Lti::Platform' do
    association :profile, factory: :user_profile

    host                   { Faker::Internet.domain_name }
    issuer                 { Faker::Internet.url host, '', 'https' }
    client_id              { SecureRandom.hex }
    deployment_id          { SecureRandom.hex }
    jwks_endpoint          do
      Faker::Internet.url(
        host, "#{'/.well-known' if rand < 0.5}/jwks#{'.json' if rand < 0.5}", 'https'
      )
    end

    transient              { auth_path { [ 'auth', 'lti', 'oauth' ].sample } }
    authorization_endpoint do
      Faker::Internet.url host, "/#{auth_path}/authoriz#{[ 'e', 'ation' ].sample}", 'https'
    end
    token_endpoint         { Faker::Internet.url host, "/#{auth_path}/token", 'https' }
  end
end
