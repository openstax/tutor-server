require 'rails_helper'

RSpec.describe CreateTeacherExercise, type: :routine do
  let(:course)    { FactoryBot.create :course_profile_course }
  let(:page)      { FactoryBot.create :content_page }
  let(:profile)   { FactoryBot.create :user_profile }
  let(:content)   { OpenStax::Exercises::V1::FakeClient.new_exercise_hash.to_json }
  let!(:invalid_derived) { FactoryBot.create :content_exercise, user_profile_id: -1 }

  context 'creating a teacher exercise' do
    it 'with valid data works' do
      allow_any_instance_of(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1)

      expect do
        @result = described_class.call(
          course: course,
          page: page,
          content: content,
          profile: profile,
          save: true
        )
      end.to change { Content::Models::Exercise.count }.by(1)

      expect(@result.errors).to be_empty
    end

    it 'with an unowned source does not work' do
      allow_any_instance_of(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1)

      expect do
        @result = described_class.call(
          course: course,
          page: page,
          content: content,
          profile: profile,
          derived_from_id: invalid_derived.id,
          save: true
        )
      end.not_to change { Content::Models::Exercise.count }

      expect(@result.errors).not_to be_empty
    end
  end
end
