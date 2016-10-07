FactoryGirl.define do
  factory :course_membership_period, class: '::CourseMembership::Models::Period' do
    association :course, factory: :entity_course

    after(:build) { |period| period.name ||= (period.course.periods.count + 1).ordinalize }
  end
end
