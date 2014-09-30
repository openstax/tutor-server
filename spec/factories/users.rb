FactoryGirl.define do
  factory :user do
    exchange_identifier { SecureRandom.hex.to_s }
    deleted_at nil

    ignore do
      username   { SecureRandom.hex.to_s }
      first_name { Faker::Name.first_name }
      last_name  { Faker::Name.last_name }
      full_name  { "#{first_name} #{last_name}" }
      title      { Faker::Name.title }
    end

    after(:build) do |user, evaluator|
      user.account = FactoryGirl.build(:openstax_accounts_account,
                                       username: evaluator.username,
                                       first_name: evaluator.first_name,
                                       last_name: evaluator.last_name,
                                       full_name: evaluator.full_name,
                                       title: evaluator.title)
    end

    trait :administrator do
      after(:build) do |user|
        user.administrator = FactoryGirl.build(:administrator, user: user)
      end
    end

    trait :agreed_to_terms do
      after(:create) do |user|
        FinePrint::Contract.all.each do |contract|
          FinePrint.sign_contract(user, contract)
        end
      end
    end
  end
end
