require 'rails_helper'

RSpec.describe CreateTeacherExercise, type: :routine do
  let(:course)    { FactoryBot.create :course_profile_course }
  let(:page)      { FactoryBot.create :content_page }
  let(:profile)   { FactoryBot.create :user_profile }
  let(:tags)      { ['time:medium', 'difficulty:medium', 'blooms:1', 'dok:2'] }
  let(:content)   { OpenStax::Exercises::V1::FakeClient.new_exercise_hash(tags: tags) }
  let!(:valid_derived) { FactoryBot.create :content_exercise, user_profile_id: profile.id }
  let!(:invalid_derived) { FactoryBot.create :content_exercise, user_profile_id: -1 }

  before do
    AddUserAsCourseTeacher[user: profile, course: course]
  end

  context 'creating a teacher exercise' do
    it 'works with valid data' do
      allow(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1)

      expect do
        @result = described_class.call(
          course: course,
          page: page,
          content: content,
          profile: profile,
          save: true
        )
      end.to change { Content::Models::Exercise.count }.by(1)

      expect(@result.outputs.exercise.tags.count).to eq(tags.count + 1) # Plus default type:practice
      expect(@result.errors).to be_empty
    end

    it 'works with an owned source' do
      allow(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1)

      expect do
        @result = described_class.call(
          course: course,
          page: page,
          content: content,
          profile: profile,
          derived_from_id: valid_derived.id,
          save: true
        )
      end.to change { Content::Models::Exercise.count }.by(1)

      expect(@result.errors).to be_empty
    end

    it 'does not work with an unowned source' do
      allow(Content::Models::Exercise).to receive(:generate_next_teacher_exercise_number).and_return(1)

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
