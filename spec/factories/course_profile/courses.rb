FactoryGirl.define do
  factory :course_profile_course, class: '::CourseProfile::Models::Course' do
    transient do
      consistent_times { false }
    end

    name                  { Faker::Lorem.words.join(' ') }

    is_preview            false

    is_concept_coach      false
    is_college            true

    term                  { CourseProfile::Models::Course.terms.keys.sample }
    year                  { Time.current.year }

    starts_at             { consistent_times ? term_year.starts_at : Time.current - 3.months }
    ends_at               { consistent_times ? term_year.ends_at : Time.current + 3.months }

    biglearn_student_clues_algorithm_name        { Faker::Hacker.abbreviation }
    biglearn_teacher_clues_algorithm_name        { Faker::Hacker.abbreviation }
    biglearn_assignment_spes_algorithm_name      { Faker::Hacker.abbreviation }
    biglearn_assignment_pes_algorithm_name       { Faker::Hacker.abbreviation }
    biglearn_practice_worst_areas_algorithm_name { Faker::Hacker.abbreviation }

    association :offering, factory: :catalog_offering

    trait(:with_assistants) do
      after(:create) { |course| Tasks::CreateCourseAssistants[course: course] }
    end

    trait(:process_school_change) do
      after(:create) { |course| SchoolDistrict::ProcessSchoolChange[course: course] }
    end

    #after(:build) do |course|
    #  course.course_ecosystems << build(
    #    :course_content_course_ecosystem,
    #    course: course,
    #    ecosystem: course.offering.ecosystem
    #  ) unless course.offering.nil?
    #end
  end
end
