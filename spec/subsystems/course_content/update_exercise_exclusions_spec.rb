require 'rails_helper'
require 'vcr_helper'

RSpec.describe CourseContent::UpdateExerciseExclusions, type: :routine do
  let(:ecosystem) { generate_mini_ecosystem }
  let(:offering) { FactoryBot.create :catalog_offering, ecosystem: ecosystem }
  let(:course) {
    FactoryBot.create :course_profile_course, :with_grading_templates,
                      offering: offering, is_preview: true
  }
  let(:period) { FactoryBot.create :course_membership_period, course: course }
  let(:exercise) { ecosystem.exercises.first }

  it 'can exclude and reinclude an exercise' do
    expect do
      @exclusions = CourseContent::UpdateExerciseExclusions[
        course: course, updates_array: [{ id: exercise.id.to_s, is_excluded: true }]
      ]
    end.to change { CourseContent::Models::ExcludedExercise.count }.by(1)

    expect(@exclusions).to be_an Array
    expect(@exclusions.first[:id]).to eq exercise.id.to_s
    expect(@exclusions.first[:is_excluded]).to eq true

    expect do
      @exclusions = CourseContent::UpdateExerciseExclusions[
        course: course, updates_array: [{ id: exercise.id.to_s, is_excluded: false }]
      ]
    end.to change { CourseContent::Models::ExcludedExercise.count }.by(-1)

    expect(@exclusions).to be_an Array
    expect(@exclusions.first[:id]).to eq exercise.id.to_s
    expect(@exclusions.first[:is_excluded]).to eq false
  end
end
