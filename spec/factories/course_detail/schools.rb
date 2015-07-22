FactoryGirl.define do
  factory :school, class: CourseDetail::Models::School do
    sequence(:name) { |n| "FactoryGirl School #{n}" }
    course_detail_district_id { FactoryGirl.create(:district).id }
  end
end
