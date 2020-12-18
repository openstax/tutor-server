require 'rails_helper'

RSpec.describe Content::Routines::RemapPracticeQuestionExercises, type: :routine do
  context 'with a new ecosystem' do
    let!(:old_exercise) { FactoryBot.create :content_exercise }
    let!(:new_exercise) { FactoryBot.create :content_exercise, number: old_exercise.number }
    let!(:practice_question) { FactoryBot.create :tasks_practice_question, exercise: old_exercise }
    let(:ecosystem) { new_exercise.ecosystem }

    it 'updates the exercise id to one in the new ecosystem' do
      old_exercise_id = practice_question.exercise.id
      result = described_class.call(ecosystem: ecosystem, save: true).outputs
      practice_question.reload

      expect(result.mapped_ids).to eq({ old_exercise_id.to_s => practice_question.exercise.id })
      expect(practice_question.exercise.id).to eq(new_exercise.id)
      expect(practice_question.exercise.ecosystem).to eq(ecosystem)
    end

    it 'skips updating if the id did not change' do
      practice_question.update_column(:content_exercise_id, new_exercise.id)
      result = described_class.call(ecosystem: ecosystem, save: true).outputs
      practice_question.reload

      expect(result.mapped_ids).to eq({})
    end
  end
end
