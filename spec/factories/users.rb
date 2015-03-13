FactoryGirl.define do
  factory :user do
    exchange_identifier { SecureRandom.hex.to_s }

    transient do
      username { SecureRandom.hex.to_s }
      first_name { SecureRandom.hex.to_s }
      last_name { SecureRandom.hex.to_s }
      full_name { SecureRandom.hex.to_s }
      title nil
    end

    after(:build) do |user, evaluator|
      user.account = FactoryGirl.build(:openstax_accounts_account,
                                       username: evaluator.username,
                                       first_name: evaluator.first_name,
                                       last_name: evaluator.last_name,
                                       full_name: evaluator.full_name,
                                       title: evaluator.title)
    end

    after(:create) do |user|
      UserProfile::FindOrCreate.call(user)
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
