require 'rails_helper'

RSpec.describe BuildTeacherExerciseContentHash, type: :routine do
  context 'with valid params' do
    it 'builds content hash in the correct format' do
      allow(SecureRandom).to receive(:uuid) { '1' }

      expected_hash = {
        questions:[
          {
            id: '1',
            is_answer_order_important: true,
            stimulus_html: '',
            title: 'Title',
            stem_html: 'Question?',
            formats: ['multiple-choice'],
            hints: [],
            answers: [
              { id: '1',
                content_html: 'answer',
                correctness: '1.0',
                feedback_html: 'feedback' },
              { id: '1',
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
        authors: [],
        uuid: '',
        group_uuid: '',
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

      result = described_class.call(data: data)
      expect(result.outputs.content_hash.deep_symbolize_keys).to eq(expected_hash)
      expect(result.errors).to be_empty
    end

    it 'sanitizes' do
      allow(SecureRandom).to receive(:uuid) { '1' }

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
          { id: '1',
            is_answer_order_important: true,
            stimulus_html: '',
            stem_html: 'Video <iframe src="https://www.youtube.com/embed/XcnpuhrnE28" frameborder="0" allowfullscreen></iframe>',
            title: '',
            collaborator_solutions: [],
            combo_choices: [],
            community_solutions: [],
            formats: ['multiple-choice'],
            hints: [],
            answers: [
              {
                id: '1',
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
        authors: [],
        uuid: '',
        group_uuid: '',
        tags: []
      }

      result = described_class.call(data: data)
      expect(result.outputs.content_hash.deep_symbolize_keys).to eq(expected_hash)
      expect(result.errors).to be_empty
    end
  end

  context 'with invalid multiple choice options' do
    it 'throws an error' do
      data = {
        questionText: 'Question?',
        questionName: 'Title',
        options: [
          {
            content: 'answer',
            correctness: '0.0',
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

      errors = described_class.call(data: data).errors
      expect(errors.first.code).to eq(:multiple_choice_must_have_valid_correctness)
    end
  end

  context 'answer order importance' do
    it 'can be set' do
      data = {
        isAnswerOrderImportant: false,
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
          },
          {
            content: 'answer',
            correctness: '0.0',
            feedback: 'feedback'
          }
        ],
        tags: { tagDifficulty: { value: 'easy' }, tagBloom: { value: '2' } }
      }

      result = described_class.call(data: data)
      question = result.outputs.content_hash.deep_symbolize_keys[:questions][0]
      expect(question[:is_answer_order_important]).to eq(false)
      expect(result.errors).to be_empty

      result = described_class.call data: data.merge({ isAnswerOrderImportant: 'true' })
      question = result.outputs.content_hash.deep_symbolize_keys[:questions][0]
      expect(question[:is_answer_order_important]).to eq(true)

      result = described_class.call data: data.merge({ isAnswerOrderImportant: 'noboolean' })
      question = result.outputs.content_hash.deep_symbolize_keys[:questions][0]
      expect(question[:is_answer_order_important]).to eq(false)
    end

    it 'is always true if there are only 2 options' do
      data = {
        isAnswerOrderImportant: false,
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

      result = described_class.call(data: data)
      question = result.outputs.content_hash.deep_symbolize_keys[:questions][0]
      expect(question[:is_answer_order_important]).to eq(true)
      expect(result.errors).to be_empty
    end
  end
end
