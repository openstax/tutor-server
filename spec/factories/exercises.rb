FactoryGirl.define do
  factory :exercise do
    content_exercise
    initialize_with { new(content_exercise) }
    to_create {}
  end
end
