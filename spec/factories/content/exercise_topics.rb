FactoryGirl.define do
  factory :content_exercise_topic, class: '::Content::Models::ExerciseTopic' do
    exercise
    topic
  end
end
