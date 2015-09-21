FactoryGirl.define do
  factory :user_profile_profile, aliases: [:profile], class: 'UserProfile::Models::Profile' do
    exchange_read_identifier  { SecureRandom.hex.to_s }
    exchange_write_identifier { SecureRandom.hex.to_s }

    transient do
      username { SecureRandom.hex.to_s }
      first_name { SecureRandom.hex.to_s }
      last_name { SecureRandom.hex.to_s }
      full_name { [first_name, last_name].join(' ') || SecureRandom.hex.to_s }
      skip_terms_agreement { false }
      title nil
    end

    association :user, factory: :entity_user

    after(:build) do |profile, evaluator|
      profile.account ||= FactoryGirl.build(:openstax_accounts_account,
                                            username: evaluator.username,
                                            first_name: evaluator.first_name,
                                            last_name: evaluator.last_name,
                                            full_name: evaluator.full_name,
                                            title: evaluator.title)
    end

    trait :administrator do
      after(:build) do |profile|
        profile.administrator = FactoryGirl.build(:user_profile_administrator, profile: profile)
      end
    end

    after(:create) do |profile, evaluator|
      unless evaluator.skip_terms_agreement
        FinePrint::Contract.all.each do |contract|
          FinePrint.sign_contract(profile, contract)
        end
      end
    end
  end
end
