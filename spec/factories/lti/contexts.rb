FactoryBot.define do
  factory :lti_context, class: '::Lti::Context' do
    association :course,  factory: :course_profile_course
    association :platform, factory: :lti_platform

    context_id { SecureRandom.hex }
  end
end
