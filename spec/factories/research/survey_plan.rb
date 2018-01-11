FactoryBot.define do
  factory :research_survey_plan, class: '::Research::Models::SurveyPlan' do
    association :study, factory: :research_study

    title_for_researchers { Faker::Lorem.sentence }
    title_for_students { Faker::Lorem.sentence }

    survey_js_model <<-MODEL
      {
       pages: [
        {
         name: "page1",
         elements: [
          {
           type: "text",
           name: "question1",
           title: "How old are you?"
          }
         ]
        },
        {
         name: "page2",
         elements: [
          {
           type: "rating",
           name: "What's your favorite number?"
          }
         ]
        }
       ]
      }
    MODEL

    trait :published do
      after(:create) do |plan|
        plan.update_attributes(published_at: Time.now)
      end
    end

    trait :hidden do
      permanently_hidden_at { Time.now }
    end
  end
end
