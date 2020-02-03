require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::CourseExercisesController, type: :controller, api: true,
                                                   version: :v1, vcr: VCR_OPTS, speed: :slow do

  let(:user_1)         { FactoryBot.create(:user_profile) }
  let(:user_1_token)   do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_1.id
  end

  let(:user_2)         { FactoryBot.create(:user_profile) }
  let(:user_2_token)   do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_2.id
  end

  let(:userless_token) { FactoryBot.create :doorkeeper_access_token }

  let(:course)         { FactoryBot.create :course_profile_course, :without_ecosystem }

  context 'with a real book' do
    before(:all) do
      VCR.use_cassette('Api_V1_CourseExercisesController/with_book', VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end
    end

    before(:each) do
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: @ecosystem)
      AddUserAsCourseTeacher.call(course: course, user: user_1)
    end

    context '#update' do
      let(:exercise) { @ecosystem.exercises.first }

      context 'for anonymous' do
        it 'raises SecurityTransgression' do
          expect do
            api_patch :update, nil, params: { course_id: course.id },
                                    body: [{ id: exercise.id, is_excluded: true }]
          end.to raise_error(SecurityTransgression)
        end
      end

      context 'for a user that is not a teacher' do
        it 'raises SecurityTransgression' do
          expect do
            api_patch :update, user_2_token,
                      params: { course_id: course.id },
                      body: [{ id: exercise.id, is_excluded: true }]
          end.to raise_error(SecurityTransgression)
        end
      end

      context 'for a teacher in the course' do
        it 'can exclude an exercise' do
          expect do
            api_patch :update, user_1_token,
                      params: { course_id: course.id },
                      body: [{ id: exercise.id, is_excluded: true }]
          end.to change { CourseContent::Models::ExcludedExercise.count }.by(1)

          expect(response).to have_http_status(:success)
          exclusions = response.body_as_hash
          expect(exclusions).to be_an Array
          expect(exclusions.first[:id]).to eq exercise.id.to_s
          expect(exclusions.first[:is_excluded]).to eq true
        end

        it 'can reinclude an exercise' do
          FactoryBot.create :course_content_excluded_exercise,
                             course: course, exercise_number: exercise.number

          expect do
            api_patch :update, user_1_token,
                      params: { course_id: course.id },
                      body: [{ id: exercise.id, is_excluded: false }]
          end.to change { CourseContent::Models::ExcludedExercise.count }.by(-1)

          expect(response).to have_http_status(:success)
          exclusions = response.body_as_hash
          expect(exclusions).to be_an Array
          expect(exclusions.first[:id]).to eq exercise.id.to_s
          expect(exclusions.first[:is_excluded]).to eq false
        end
      end
    end
  end

end
