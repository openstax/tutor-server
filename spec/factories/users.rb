FactoryGirl.define do
  factory :user, class: 'User::User' do
    skip_create

    transient do
      profile create(:user_profile)
      strategy User::Strategies::Direct::User.new(profile)
    end

    initialize_with { new(strategy: strategy) }
  end
end
