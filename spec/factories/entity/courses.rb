FactoryGirl.define do
  factory :entity_course, class: '::Entity::Course' do
    transient do
      name             nil
      is_concept_coach nil
      is_college       nil
      starts_at        nil
      ends_at          nil
      catalog_offering nil
      appearance_code  nil
      time_zone        nil
      offering         nil
      school           nil
    end

    trait(:with_assistants) do
      after(:create) { |course| Tasks::CreateCourseAssistants[course: course] }
    end

    trait(:process_school_change) do
      after(:create) do |course|
        SchoolDistrict::ProcessSchoolChange[course_profile: course.profile]
      end
    end

    after(:build) do |course, evaluator|
      name             = evaluator.name      || Faker::Lorem.words.join(' ')

      is_concept_coach = evaluator.is_concept_coach.nil? ? false : evaluator.is_concept_coach
      is_college       = evaluator.is_college.nil?       ? true  : evaluator.is_college

      starts_at        = evaluator.starts_at || Time.current
      ends_at          = evaluator.ends_at   || Time.current + 1.week

      course.profile ||= build(:course_profile_profile,
                               course: course,
                               name: name,
                               is_concept_coach: is_concept_coach,
                               is_college: is_college,
                               starts_at: starts_at,
                               ends_at: ends_at,
                               offering: evaluator.catalog_offering.try!(:to_model),
                               appearance_code: evaluator.appearance_code,
                               school: evaluator.school,
                               time_zone: evaluator.time_zone)
    end
  end
end
