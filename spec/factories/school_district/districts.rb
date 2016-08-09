FactoryGirl.define do
  factory :school_district_district, class: SchoolDistrict::Models::District do
    sequence(:name) { |n| "FactoryGirl District #{n}" }
  end
end
