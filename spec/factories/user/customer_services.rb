FactoryBot.define do
  factory :user_customer_service, class: 'User::Models::CustomerService' do
    association :profile, factory: :user_profile
  end
end
