FactoryBot.define do
  factory :content_exercise, class: '::Content::Models::Exercise' do
    association :page, factory: :content_page

    sequence(:number)   { |n| -n }
    version             { 1 }

    transient           do
      uid               { nil }
      tags              { nil }
      num_questions     { 1 }

      wrapper           { OpenStax::Exercises::V1::Exercise.new(content: content) }
    end

    content             do
      OpenStax::Exercises::V1::FakeClient.new_exercise_hash(
        number: number, version: version, uid: uid, tags: tags, num_questions: num_questions
      ).to_json
    end
    number_of_questions { wrapper.questions.size }
    question_answer_ids { wrapper.question_answer_ids }

    uuid                { wrapper.uuid       }
    group_uuid          { wrapper.group_uuid }
    url                 { wrapper.url        }
    title               { wrapper.title      }

    trait :free_response_only do
      after(:build) do |exercise, evaluator|
        exercise.parser.questions.each{|q| q['answers'].clear }
        exercise.question_answer_ids.each{|a| a.clear }
      end
    end
  end
end
