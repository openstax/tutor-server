FactoryBot.define do
  factory :course_profile_cache, class: '::CourseProfile::Models::Cache' do
    association :course, factory: :course_profile_course

    teacher_performance_report { [] }
  end
end
