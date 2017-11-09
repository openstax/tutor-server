FactoryBot.define do
  factory :school_district_district, class: SchoolDistrict::Models::District do
    sequence(:name) { |n| "FactoryBot District #{n}" }
  end
end
