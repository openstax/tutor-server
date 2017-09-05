FactoryGirl.define do
  factory :lms_app, class: '::Lms::Models::App' do
    association :owner, factory: :course_profile_course
  end
end
