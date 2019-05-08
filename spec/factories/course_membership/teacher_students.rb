FactoryBot.define do
  factory :course_membership_teacher_student, class: '::CourseMembership::Models::TeacherStudent' do
    association :role, factory: :entity_role
    association :period, factory: :course_membership_period

    after(:build) do |teacher_student|
      teacher_student.course ||= teacher_student.period.course

      teacher_student.role.teacher_student!
    end
  end
end
