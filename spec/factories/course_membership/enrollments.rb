FactoryGirl.define do
  factory :course_membership_enrollment, class: '::CourseMembership::Models::Enrollment' do
    association :period, factory: :course_membership_period

    after(:build) do |enrollment|
      enrollment.student ||= build :course_membership_student, course: enrollment.period.course
    end
  end
end
