FactoryGirl.define do
  factory :course_profile_profile, class: '::CourseProfile::Models::Profile' do
    name { Faker::Lorem.words.join(' ') }
    timezone { ActiveSupport::TimeZone.all.collect(&:name).sample }
    is_concept_coach false

    trait :with_offering do
      association :offering, factory: :catalog_offering
    end

    after(:build) do |profile, evaluator|
      profile.course ||= build(:entity_course, profile: profile)
    end
  end
end
