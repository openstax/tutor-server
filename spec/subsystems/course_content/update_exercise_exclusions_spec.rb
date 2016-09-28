require 'rails_helper'
require 'vcr_helper'

RSpec.describe CourseContent::UpdateExerciseExclusions, type: :routine do

  let(:course)         { FactoryGirl.create :course_profile_course }
  let(:period)         { FactoryGirl.create :course_membership_period, course: course }

  context 'with a real book' do
    before(:all) do
      VCR.use_cassette('CourseContent_UpdateExerciseExclusions/with_book', VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end
    end

    before(:each) do
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: @ecosystem)
    end

    let(:exercise) { @ecosystem.exercises.first }

    it 'can exclude and reinclude an exercise' do
      expect{
        @exclusions = CourseContent::UpdateExerciseExclusions[
          course: course, updates_array: [{ id: exercise.id.to_s, is_excluded: true }]
        ]
      }.to change{ CourseContent::Models::ExcludedExercise.count }.by(1)

      expect(@exclusions).to be_an Array
      expect(@exclusions.first[:id]).to eq exercise.id.to_s
      expect(@exclusions.first[:is_excluded]).to eq true

      expect{
        @exclusions = CourseContent::UpdateExerciseExclusions[
          course: course, updates_array: [{ id: exercise.id.to_s, is_excluded: false }]
        ]
      }.to change{ CourseContent::Models::ExcludedExercise.count }.by(-1)

      expect(@exclusions).to be_an Array
      expect(@exclusions.first[:id]).to eq exercise.id.to_s
      expect(@exclusions.first[:is_excluded]).to eq false
    end
  end

end
