FactoryGirl.define do
  factory :course_profile_profile, class: '::CourseProfile::Models::Profile' do
    name                  { Faker::Lorem.words.join(' ') }

    is_concept_coach      false
    is_college            true

    starts_at             { Time.current }
    ends_at               { Time.current + 1.week }

    trait(:with_offering) { association :offering, factory: :catalog_offering }

    after(:build)         do |profile, evaluator|
      profile.course ||= build(:entity_course, profile: profile)
    end
  end
end
