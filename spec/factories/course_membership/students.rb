FactoryGirl.define do
  factory :course_membership_student, class: '::CourseMembership::Models::Student' do
    association :role, factory: :entity_role
    association :period, factory: :course_membership_period
    course { period.course }
  end
end
