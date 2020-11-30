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

    data = {
      question: 'Question',
      answers: [],
      tags: ["blooms:2","book:stax-soc"]
    }

    output_hash = described_class.call(data: data).outputs.content_hash
    expect(output_hash).to eq(content_hash)
  end

  it 'sanitizes' do
    data = {
      questionText:
        'Video <iframe src="https://www.youtube.com/embed/XcnpuhrnE28" frameborder="0" allowfullscreen></iframe>' +
        '<iframe src="https://www.youtube2.com/embed/"></iframe>',
      options: [
        {
          content: '<span id="1" data-math="\\text{CaCO}_3\">\\text{CaCO}_3</span>',
          correctness: '1.0',
          feedback: 'Feedback'
        }
      ]
    }

    expected_hash = {
      tags: [],
      formats: ["multiple-choice"],
      questions: [
        { id: 1,
          is_answer_order_important: true,
          stimulus_html: "",
          stem_html: 'Video <iframe src="https://www.youtube.com/embed/XcnpuhrnE28" frameborder="0" allowfullscreen></iframe>',
          title: nil,
          collaborator_solutions: [],
          answers: [
            {
              id: 1,
              content_html: '<span data-math="\\text{CaCO}_3\">\\text{CaCO}_3</span>',
              correctness: '1.0',
              feedback_html: 'Feedback'
            }
          ]
        }
      ]
    }

    content_hash = described_class.call(data: data).outputs.content_hash
    expect(content_hash.deep_symbolize_keys).to eq(expected_hash)
  end
end
