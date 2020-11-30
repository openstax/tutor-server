require 'rails_helper'

RSpec.describe BuildTeacherExerciseContentHash, type: :routine do
  it 'builds content hash in the correct format' do
    expected_hash = {
      questions:[
        {
          id: 1,
          is_answer_order_important: true,
          stimulus_html: '',
          title: 'Title',
          stem_html: 'Question?',
          answers: [
            { id: 1,
              content_html: 'answer',
              correctness: '1.0',
              feedback_html: 'feedback' },
            { id: 2,
              content_html: 'answer',
              correctness: '0.0',
              feedback_html: 'feedback' }
          ],
          combo_choices: [],
          collaborator_solutions: [],
          community_solutions: []
        }
      ],
      stimulus_html: '',
      derived_from: [],
      is_vocab: false,
      hints: [],
      authors: [],
      uuid: '',
      group_uuid: '',
      formats: ['multiple-choice'],
      tags: ['difficulty:easy', 'blooms:2']
    }

    data = {
      questionText: 'Question?',
      questionName: 'Title',
      options: [
        {
          content: 'answer',
          correctness: '1.0',
          feedback: 'feedback'
        },
        {
          content: 'answer',
          correctness: '0.0',
          feedback: 'feedback'
        }
      ],
      tags: { tagDifficulty: { value: 'easy' }, tagBloom: { value: '2' } }
    }

    output_hash = described_class.call(data: data).outputs.content_hash
    expect(output_hash.deep_symbolize_keys).to eq(expected_hash)
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
      questions: [
        { id: 1,
          is_answer_order_important: true,
          stimulus_html: '',
          stem_html: 'Video <iframe src="https://www.youtube.com/embed/XcnpuhrnE28" frameborder="0" allowfullscreen></iframe>',
          title: '',
          collaborator_solutions: [],
          combo_choices: [],
          community_solutions: [],
          answers: [
            {
              id: 1,
              content_html: '<span data-math="\\text{CaCO}_3\">\\text{CaCO}_3</span>',
              correctness: '1.0',
              feedback_html: 'Feedback'
            }
          ]
        }
      ],
      stimulus_html: '',
      derived_from: [],
      is_vocab: false,
      hints: [],
      authors: [],
      uuid: '',
      group_uuid: '',
      formats: ['multiple-choice'],
      tags: []
    }

    content_hash = described_class.call(data: data).outputs.content_hash
    expect(content_hash.deep_symbolize_keys).to eq(expected_hash)
  end
end
