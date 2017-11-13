FactoryBot.define do
  factory :course_content_course_ecosystem, class: '::CourseContent::Models::CourseEcosystem' do
    association :course, factory: :course_profile_course
    association :ecosystem, factory: :content_ecosystem
  end
end
