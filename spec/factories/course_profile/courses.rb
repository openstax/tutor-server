FactoryGirl.define do
  factory :course_profile_course, class: '::CourseProfile::Models::Course' do
    name                  { Faker::Lorem.words.join(' ') }

    is_concept_coach      false
    is_college            true

    term                  { CourseProfile::Models::Course.terms.keys.sample }
    year                  { Time.current.year }

    starts_at             { Time.current - 3.months }
    ends_at               { Time.current + 3.months }

    association :offering, factory: :catalog_offering

    trait(:with_assistants) do
      after(:create) { |course| Tasks::CreateCourseAssistants[course: course] }
    end

    trait(:process_school_change) do
      after(:create) { |course| SchoolDistrict::ProcessSchoolChange[course: course] }
    end
  end
end
