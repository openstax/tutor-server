FactoryBot.define do
  factory :course_membership_teacher, class: '::CourseMembership::Models::Teacher' do
    association :role, factory: :entity_role
    association :course, factory: :course_profile_course

    after(:build) { |teacher| teacher.role.teacher! }
  end
end
