FactoryGirl.define do
  factory :period do
    course_membership_period
    initialize_with { new(course_membership_period) }
    to_create {}
  end
end
