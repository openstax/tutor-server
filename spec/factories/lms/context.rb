FactoryBot.define do
  factory :lms_context, class: 'Lms::Models::Context' do
    association :course, factory: :course_profile_course
    association :tool_consumer, factory: :lms_tool_consumer

    lti_id { SecureRandom.uuid }
    app_type { Lms::Models::App.to_s }
  end
end
