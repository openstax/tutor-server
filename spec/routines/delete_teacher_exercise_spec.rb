require 'rails_helper'

RSpec.describe DeleteTeacherExercise, type: :routine do
  let(:author)      { FactoryBot.create :user_profile }

  let!(:exercise_1) { FactoryBot.create :content_exercise, user_profile_id: 0 }
  let!(:exercise_2) { FactoryBot.create :content_exercise, profile: author, number: 1000000 }
  let!(:exercise_3) do
    FactoryBot.create :content_exercise, profile: author, number: exercise_2.number
  end

  context 'when the given number is invalid' do
    let(:number) { -1 }

    it 'does not delete any exercises and raises an exception' do
      expect do
        described_class.call number: number
      end.to  raise_error(RuntimeError)
         .and not_change { exercise_1.reload.deleted? }
         .and not_change { exercise_2.reload.deleted? }
         .and not_change { exercise_3.reload.deleted? }
    end
  end

  context "when the given number is not a teacher exercise's number" do
    let(:number) { exercise_1.number }

    it 'does not delete any exercises and raises an exception' do
      expect do
        described_class.call number: number
      end.to  raise_error(RuntimeError)
         .and not_change { exercise_1.reload.deleted? }
         .and not_change { exercise_2.reload.deleted? }
         .and not_change { exercise_3.reload.deleted? }
    end
  end

  context "when the given exercise is a teacher exercise's number" do
    let(:number) { exercise_2.number }

    it 'deletes all teacher exercises with that number' do
      expect do
        described_class.call number: number
      end.to  not_change { exercise_1.reload.deleted? }
         .and change     { exercise_2.reload.deleted? }
         .and change     { exercise_3.reload.deleted? }
    end
  end
end
