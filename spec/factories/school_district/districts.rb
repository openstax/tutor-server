FactoryGirl.define do
  factory :district, class: SchoolDistrict::Models::District do
    sequence(:name) { |n| "FactoryGirl District #{n}" }
  end
end
