FactoryGirl.define do
  factory :course_profile_profile, class: '::CourseProfile::Models::Profile' do
    association :course, factory: :entity_course
    name { Faker::Lorem.words.join(' ') }
    timezone { ActiveSupport::TimeZone.all.collect(&:name).sample }
  end
end
