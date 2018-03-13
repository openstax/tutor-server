FactoryBot.define do
  factory :lms_course_score_callback, class: 'Lms::Models::CourseScoreCallback' do
    association :course, factory: :course_profile_course
    association :profile, factory: :user_profile

    resource_link_id { Faker::Internet.url }
    outcome_url      { Faker::Internet.url }
    result_sourcedid { SecureRandom.uuid }
  end
end
