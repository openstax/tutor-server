require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::CourseExercisesController, type: :request, api: true,
                                                   version: :v1, vcr: VCR_OPTS do
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

    context '#create' do
      let(:page) { @ecosystem.pages.first }

      it 'creates an exercise by a teacher' do
        params = {
          selectedChapterSection: page.id,
          questionText: 'Test'
        }

        expect do
          api_post api_course_exercises_url(course.id), user_1_token,
                     params: params.to_json
        end.to change { Content::Models::Exercise.count }.by(1)
      end
    end

    context '#exlude' do
      let(:exercise) { @ecosystem.exercises.first }

      context 'for anonymous' do
        it 'raises SecurityTransgression' do
          expect do
            api_put exclude_api_course_exercises_url(course.id), nil,
                      params: [ { id: exercise.id, is_excluded: true } ].to_json
          end.to raise_error(SecurityTransgression)
        end
      end

      context 'for a user that is not a teacher' do
        it 'raises SecurityTransgression' do
          expect do
            api_put exclude_api_course_exercises_url(course.id), user_2_token,
                      params: [ { id: exercise.id, is_excluded: true } ].to_json
          end.to raise_error(SecurityTransgression)
        end
      end

      context 'for a teacher in the course' do
        it 'can exclude an exercise' do
          expect do
            api_put exclude_api_course_exercises_url(course.id), user_1_token,
                      params: [ { id: exercise.id, is_excluded: true } ].to_json
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
            api_put exclude_api_course_exercises_url(course.id), user_1_token,
                      params: [ { id: exercise.id, is_excluded: false } ].to_json
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
