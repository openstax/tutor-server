FactoryGirl.define do
  factory :administrator, class: 'UserProfile::Administrator' do
    user
  end
end
