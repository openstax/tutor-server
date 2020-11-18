require 'rails_helper'

RSpec.describe BuildTeacherExerciseContentHash, type: :routine do
  it 'builds content hash in the correct format' do
    content_hash = {
      "tags": ["blooms:2","book:stax-soc"],
      "is_vocab":false,
      "stimulus_html":"",
      "questions":[
        {
          "is_answer_order_important":false,
          "stimulus_html":"",
          "stem_html":"Question?",
          "answers":[
            {"id":1,
              "content_html": "answer",
              "correctness":"0.0",
              "feedback_html":"feedback"},
            {"id":2,
              "content_html": "answer",
              "correctness":"0.0",
              "feedback_html":"feedback"},
            {"id":3,
              "content_html": "answer",
              "correctness":"0.0",
              "feedback_html":"feedback"},
            {"id":4,
              "content_html": "answer",
              "correctness":"0.0",
              "feedback_html":"feedback"},
          ],
          "hints":[],
          "formats": ["multiple-choice"],
          "combo_choices": [],
          "collaborator_solutions": [],
          "community_solutions": []
        }
      ],
      "attachments":[],
      "delegations":[],
      "versions":[1]
    }

    params = [
      question: 'Question',
      answers: [],
      tags: ["blooms:2","book:stax-soc"]
    ]

    output_hash = described_class.call(*params).outputs.content_hash
    expect(output_hash).to eq(content_hash)
  end
end
