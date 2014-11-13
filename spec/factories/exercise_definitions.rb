FactoryGirl.define do
  sequence :exercise_url do |n| "https://exercises.openstax.org/exercises/e#{n}" end
  sequence :exercise_component_id do |n| n end

  factory :exercise_definition do
    klass
    url { generate(:exercise_url) }
    content {
      {
        stimulus: "This is fake exercise #{url}.  <span data-math='\\dfrac{-b \\pm \\sqrt{b^2 - 4ac}}{2a}'></span>",
        questions: [
          {
            id: "#{generate(:exercise_component_id)}",
            format: "short-answer",
            stem: "What is the answer to this question?"
          },
          {
            id: "#{generate(:exercise_component_id)}",
            format: "multiple-choice",
            stem: "Select the answer that makes the most sense.",
            answers:[
              {id: "#{generate(:exercise_component_id)}", content: "10 N"},
              {id: "#{generate(:exercise_component_id)}", content: "1 N"}
            ]
          }
        ]
      }
    }
  end
end
