FactoryGirl.define do
  factory :administrator, class: 'UserProfile::Models::Administrator' do
    profile
  end
end
