FactoryGirl.define do
  factory :content_exercise_topic, class: '::Content::ExerciseTopic' do
    content_exercise
    content_topic
  end
end
