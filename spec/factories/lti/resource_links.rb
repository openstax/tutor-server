FactoryBot.define do
  factory :lti_resource_link do
    association :platform, factory: :lti_platform

    context_id           { SecureRandom.hex }
    resource_link_id     { SecureRandom.hex }
    lineitems_endpoint   { Faker::Internet.url platform.host, nil, 'https' }
    lineitem_endpoint    { Faker::Internet.url platform.host, nil, 'https' }
    can_create_lineitems { [ true, false ].sample }
    can_update_scores    { [ true, false ].sample }
  end
end
