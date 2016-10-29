FactoryGirl.define do
  factory :course_content_excluded_exercise, class: '::CourseContent::Models::ExcludedExercise' do
    association :course, factory: :course_profile_course
    exercise_number { SecureRandom.hex(4).to_i(16)/2 }
  end
end
