FactoryGirl.define do
  factory :school, class: SchoolDistrict::Models::School do
    sequence(:name) { |n| "FactoryGirl School #{n}" }
    school_district_district_id { FactoryGirl.create(:district).id }
  end
end
