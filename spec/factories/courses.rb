FactoryGirl.define do
  sequence :course_number do |n| "#{n}" end
  
  factory :course do
    transient do
      course_number { generate(:course_number) }
    end

    name { "Course #{course_number}" }
    short_name { "C#{course_number}" }
    description Faker::Lorem.paragraph
    school
  end
end
