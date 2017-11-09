FactoryBot.define do
  factory :anonymous_user, class: '::User::User' do
    transient do
      profile { User::Models::AnonymousProfile.instance }
      strategy { User::Strategies::Direct::AnonymousUser.new(profile) }
    end

    skip_create
    initialize_with { new(strategy: strategy) }
  end
end
