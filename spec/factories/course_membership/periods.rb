FactoryGirl.define do
  factory :course_membership_period, class: '::CourseMembership::Models::Period' do
    association :course, factory: :entity_course
    name { SecureRandom.hex }
  end
end
