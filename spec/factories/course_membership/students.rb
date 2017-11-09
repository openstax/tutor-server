FactoryBot.define do
  factory :course_membership_student, class: '::CourseMembership::Models::Student' do
    association :role, factory: :entity_role
    association :course, factory: :course_profile_course

    payment_due_at do
      course.time_zone.to_tz.now.midnight + 1.day - 1.second +
      Settings::Payments.student_grace_period_days.days
    end
  end
end
