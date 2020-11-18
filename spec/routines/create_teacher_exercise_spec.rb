require 'rails_helper'

RSpec.describe CreateTeacherExercise, type: :routine do
  let(:course)    { FactoryBot.create :course_profile_course }
  let(:ecosystem) { course.ecosystem  }
  let(:page)      { FactoryBot.create :content_page }
  let(:profile)   { FactoryBot.create :user_profile }
  let(:content)   { OpenStax::Exercises::V1::FakeClient.new_exercise_hash.to_json }

  it 'creates an exercise' do
    expect do
      exercise = described_class.call(
        ecosystem: ecosystem,
        page: page,
        content: content,
        profile: profile,
        save: true
      )
    end.to change { Content::Models::Exercise.count }.by(1)
  end
end
