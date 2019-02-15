FactoryBot.define do
  factory :lms_app, class: '::Lms::Models::App' do
    association :owner, factory: :course_profile_course
    # after(:build) do |app, evaluator|
    #   app.owner.lms_context = FactoryBot.create :lms_context, course: app.owner
    # end
  end
end
