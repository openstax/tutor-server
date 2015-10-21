FactoryGirl.define do
  factory :user, class: 'User::User' do
    skip_create

    transient do
      profile FactoryGirl.create(:user_profile)
      strategy User::Strategies::Direct::user.new(profile)
    end

    strategy { strategy }
  end
end
