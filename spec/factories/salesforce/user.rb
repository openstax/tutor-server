FactoryGirl.define do
  factory :salesforce_user, class: 'Salesforce::Models::User' do
    uid           { SecureRandom.hex(10) }
    name          { Faker::Name.name }
    oauth_token   { SecureRandom.hex }
    refresh_token { SecureRandom.hex }
    instance_url  { Faker::Internet.url }
  end
end
