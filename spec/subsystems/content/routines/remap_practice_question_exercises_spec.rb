require 'rails_helper'

RSpec.describe Content::Routines::RemapPracticeQuestionExercises, type: :routine do
  context 'with a new ecosystem' do
    let(:course)       { FactoryBot.create :course_profile_course }
    let(:period)       { FactoryBot.create :course_membership_period, course: course }
    let(:student_user) { FactoryBot.create(:user_profile) }
    let(:student_role) { AddUserAsPeriodStudent[user: student_user, period: period] }

    let(:second_course) { FactoryBot.create :course_profile_course }
    let(:second_period) { FactoryBot.create :course_membership_period, course: second_course }
    let(:second_user)   { FactoryBot.create(:user_profile) }
    let(:second_role)   { AddUserAsPeriodStudent[user: second_user, period: second_period] }

    let!(:old_exercise) { FactoryBot.create :content_exercise }
    let!(:new_exercise) { FactoryBot.create :content_exercise, number: old_exercise.number }

    let!(:practice_question) do
      FactoryBot.create :tasks_practice_question, exercise: old_exercise, role: student_role
    end
    let!(:unmapped_practice_question) do
      FactoryBot.create :tasks_practice_question, exercise: old_exercise, role: second_role
    end
    let(:ecosystem) { new_exercise.ecosystem }

    it 'updates the exercise id to one in the new ecosystem' do
      old_exercise_id = practice_question.exercise.id
      result = described_class.call(ecosystem: ecosystem, course: course, save: true).outputs
      practice_question.reload

      expect(result.mapped_ids).to eq({ old_exercise_id.to_s => practice_question.exercise.id })
      expect(practice_question.exercise.id).to eq(new_exercise.id)
      expect(practice_question.exercise.ecosystem).to eq(ecosystem)
    end

    it 'skips updating if the id did not change' do
      practice_question.update_column(:content_exercise_id, new_exercise.id)
      result = described_class.call(ecosystem: ecosystem, course: course, save: true).outputs
      practice_question.reload

      expect(result.mapped_ids).to eq({})
    end
  end
end
