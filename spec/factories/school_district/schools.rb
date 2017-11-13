FactoryBot.define do
  factory :school_district_school, class: SchoolDistrict::Models::School do
    sequence(:name) { |n| "FactoryBot School #{n}" }
    association :district, factory: :school_district_district
  end
end
