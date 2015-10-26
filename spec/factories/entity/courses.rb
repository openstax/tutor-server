FactoryGirl.define do
  factory :entity_course, class: '::Entity::Course' do
    after(:build) do |course, evaluator|
      course.profile ||= build(:course_profile_profile, course: course)
    end
  end
end
