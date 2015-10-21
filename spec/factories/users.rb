FactoryGirl.define do
  factory :user, class: 'User::User' do
    skip_create

    profile { create(:user_profile) }

    transient do
      strategy User::Strategies::Direct::User.new(profile)
    end

    initialize_with { new(strategy: strategy) }
  end
end
