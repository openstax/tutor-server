FactoryGirl.define do
  factory :school_district_school, class: SchoolDistrict::Models::School do
    sequence(:name) { |n| "FactoryGirl School #{n}" }
    association :district, factory: :school_district_district
  end
end
