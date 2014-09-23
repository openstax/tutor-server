# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    exchange_identifer "MyString"
    account_id 1
    deleted_at "2014-09-23 12:29:54"
  end
end
