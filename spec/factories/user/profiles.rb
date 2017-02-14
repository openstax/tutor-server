FactoryGirl.define do
  factory :user_profile, aliases: [:profile], class: 'User::Models::Profile' do
    transient do
      username { SecureRandom.hex.to_s }
      first_name { SecureRandom.hex.to_s }
      last_name { SecureRandom.hex.to_s }
      full_name { [first_name, last_name].join(' ') || SecureRandom.hex.to_s }
      skip_terms_agreement { false }
      title nil
      salesforce_contact_id nil
    end

    after(:build) do |profile, evaluator|
      profile.account ||= FactoryGirl.build(:openstax_accounts_account,
                                            username: evaluator.username,
                                            first_name: evaluator.first_name,
                                            last_name: evaluator.last_name,
                                            full_name: evaluator.full_name,
                                            title: evaluator.title,
                                            salesforce_contact_id: evaluator.salesforce_contact_id)
    end

    trait :administrator do
      after(:build) do |profile|
        profile.administrator = FactoryGirl.build(:user_administrator, profile: profile)
      end
    end

    trait :customer_service do
      after(:build) do |profile|
        profile.customer_service = FactoryGirl.build(:user_customer_service, profile: profile)
      end
    end

    trait :content_analyst do
      after(:build) do |profile|
        profile.content_analyst = FactoryGirl.build(:user_content_analyst, profile: profile)
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
