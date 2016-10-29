FactoryGirl.define do
  factory :course_membership_student, class: '::CourseMembership::Models::Student' do
    association :role, factory: :entity_role
    association :course, factory: :course_profile_course
  end
end
