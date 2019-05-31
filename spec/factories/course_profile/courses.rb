FactoryBot.define do
  factory :course_profile_course, class: '::CourseProfile::Models::Course' do
    transient             { consistent_times { false } }

    name                  { Faker::Lorem.words.join(' ') }

    is_preview            { false }

    is_concept_coach      { false }
    is_college            { [ true, false, nil ].sample }

    # Preview term dates are based on DateTime.current, so they lead to flaky tests
    term                  { (CourseProfile::Models::Course.terms.keys - [ 'preview' ]).sample }
    year                  { Time.current.year }

    starts_at             { consistent_times ? term_year.starts_at : Time.current - 3.months }
    ends_at               { consistent_times ? term_year.ends_at : Time.current + 3.months }

    uuid                  { SecureRandom.uuid }

    sequence_number       { rand(1000) + 1 }

    is_lms_enabling_allowed { is_lms_enabled == true ? true : false }

    association :offering, factory: :catalog_offering

    after(:build) do |course|
      course.course_ecosystems << build(
        :course_content_course_ecosystem,
        course: course,
        ecosystem: course.offering.ecosystem
      ) if course.offering.present?
    end

    trait(:with_assistants) do
      after(:create) { |course| Tasks::CreateCourseAssistants[course: course] }
    end

    trait(:without_ecosystem) do
      after(:build) { |course| course.course_ecosystems.delete_all :delete_all }
    end

  end
end
