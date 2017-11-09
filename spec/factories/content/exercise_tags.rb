FactoryBot.define do
  factory :content_exercise_tag, class: '::Content::Models::ExerciseTag' do
    association :exercise, factory: :content_exercise
    association :tag, factory: :content_tag
  end
end
