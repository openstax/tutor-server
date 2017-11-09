FactoryBot.define do
  factory :course_membership_period, class: '::CourseMembership::Models::Period' do
    association :course, factory: :course_profile_course

    after(:build) { |period| period.name ||= (period.course.periods.count + 1).ordinalize }
  end
end
