FactoryGirl.define do
  factory :course_membership_student, class: '::CourseMembership::Models::Student' do
    association :role, factory: :entity_role
    association :course, factory: :entity_course
  end
end
