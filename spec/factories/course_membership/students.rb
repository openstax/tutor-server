FactoryBot.define do
  factory :course_membership_student, class: '::CourseMembership::Models::Student' do
    association :role, factory: :entity_role
    association :period, factory: :course_membership_period

    payment_due_at do
      period.course.time_zone.now.midnight + 1.day - 1.second +
      Settings::Payments.student_grace_period_days.days
    end

    after(:build) do |student|
      student.course ||= student.period.course

      student.role.student!
    end
  end
end
