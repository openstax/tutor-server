require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::EcosystemsController, type: :request, api: true,
                                              version: :v1, vcr: VCR_OPTS, speed: :slow do
  let(:user_1)          { FactoryBot.create(:user_profile) }
  let(:user_1_token)    do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_1.id
  end

  let(:user_2)          { FactoryBot.create(:user_profile) }
  let(:user_2_token)    do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_2.id
  end

  let(:userless_token)  { FactoryBot.create :doorkeeper_access_token }

  let(:content_analyst) { FactoryBot.create(:user_profile, :content_analyst) }

  let(:ca_user_token)   do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: content_analyst.id
  end

  let(:course)          { FactoryBot.create :course_profile_course }
  let(:period)          { FactoryBot.create :course_membership_period, course: course }

  let(:student_user) { FactoryBot.create(:user_profile) }
  let(:student_role) { AddUserAsPeriodStudent[user: student_user, period: period] }
  let(:student_user_token) do
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: student_user.id
  end

  context 'with a fake book' do
    let(:book)       { FactoryBot.create(:content_book, :standard_contents_1) }
    let!(:ecosystem) do
      book.ecosystem.reload.tap do |ecosystem|
        CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
      end
    end

    context '#index' do
      it 'raises SecurityTransgression unless user is a content analyst' do
        expect { api_get api_ecosystems_url, nil }.to raise_error(SecurityTransgression)

        expect { api_get api_ecosystems_url, user_2_token }.to raise_error(SecurityTransgression)
      end

      it 'allows a content analyst to access' do
        expect { api_get api_ecosystems_url, ca_user_token }.not_to raise_error
      end
    end

    context '#readings' do
      it 'raises SecurityTransgression if user is anonymous or not in the course' do
        expect do
          api_get readings_api_ecosystem_url(ecosystem.id), nil
        end.to raise_error(SecurityTransgression)

        expect do
          api_get readings_api_ecosystem_url(ecosystem.id), user_1_token
        end.to raise_error(SecurityTransgression)
      end

      it 'works for students in the course' do
        AddUserAsCourseTeacher.call(course: course, user: user_1)
        AddUserAsPeriodStudent.call(period: period, user: user_2)

        api_get readings_api_ecosystem_url(ecosystem.id), user_1_token
        expect(response).to have_http_status(:success)
        teacher_response = response.body_as_hash

        api_get readings_api_ecosystem_url(ecosystem.id), user_2_token
        expect(response).to have_http_status(:success)
        student_response = response.body_as_hash

        expect(teacher_response).to eq(student_response)
      end

      it 'works for teachers in the course' do
        AddUserAsCourseTeacher.call(course: course, user: user_1)

        api_get readings_api_ecosystem_url(ecosystem.id), user_1_token
        expect(response).to have_http_status(:success)
        expect(response.body_as_hash).to eq(
          [
            {
              id: ecosystem.books.first.id.to_s,
              uuid: ecosystem.books.first.uuid,
              version: ecosystem.books.first.version,
              ox_id: ecosystem.books.first.ox_id,
              short_id: ecosystem.books.first.short_id,
              is_collated: false,
              title: ecosystem.books.first.title,
              type: 'book',
              chapter_section: [],
              children: [
                {
                  uuid: ecosystem.books.first.chapters.first.uuid,
                  version: ecosystem.books.first.chapters.first.version,
                  ox_id: ecosystem.books.first.chapters.first.ox_id,
                  short_id: ecosystem.books.first.chapters.first.short_id,
                  title: 'chapter 1',
                  type: 'chapter',
                  chapter_section: [1],
                  children: [
                    {
                      id: ecosystem.books.first.as_toc.pages.first.id.to_s,
                      uuid: ecosystem.books.first.as_toc.pages.first.uuid,
                      version: ecosystem.books.first.as_toc.pages.first.version,
                      ox_id: ecosystem.books.first.as_toc.pages.first.ox_id,
                      short_id: ecosystem.books.first.as_toc.pages.first.short_id,
                      title: 'first page',
                      chapter_section: [1, 1],
                      type: 'page'
                    },
                    {
                      id: ecosystem.books.first.as_toc.pages.second.id.to_s,
                      uuid: ecosystem.books.first.as_toc.pages.second.uuid,
                      version: ecosystem.books.first.as_toc.pages.second.version,
                      ox_id: ecosystem.books.first.as_toc.pages.second.ox_id,
                      short_id: ecosystem.books.first.as_toc.pages.second.short_id,
                      title: 'second page',
                      chapter_section: [1, 2],
                      type: 'page'
                    }
                  ]
                },
                {
                  uuid: ecosystem.books.first.chapters.second.uuid,
                  version: ecosystem.books.first.chapters.second.version,
                  ox_id: ecosystem.books.first.chapters.second.ox_id,
                  short_id: ecosystem.books.first.chapters.second.short_id,
                  title: 'chapter 2',
                  type: 'chapter',
                  chapter_section: [2],
                  children: [
                    {
                      id: ecosystem.books.first.chapters.second.pages.first.id.to_s,
                      uuid: ecosystem.books.first.chapters.second.pages.first.uuid,
                      version: ecosystem.books.first.chapters.second.pages.first.version,
                      ox_id: ecosystem.books.first.chapters.second.pages.first.ox_id,
                      short_id: ecosystem.books.first.chapters.second.pages.first.short_id,
                      title: 'third page',
                      chapter_section: [2, 1],
                      type: 'page'
                    }
                  ]
                }
              ]
            }
          ]
        )
      end
    end
  end

  context 'with a real book' do
    let(:ecosystem) { FactoryBot.create :mini_ecosystem }
    let(:book) { ecosystem.books.first }
    let(:offering) { FactoryBot.create :catalog_offering, ecosystem: ecosystem }
    let(:course) {
      FactoryBot.create :course_profile_course, :with_grading_templates,
                        offering: offering, is_preview: true
    }

    before(:each) do
      AddUserAsCourseTeacher.call(course: course, user: user_1)
    end

    context '#exercises' do
      def exercises_api_ecosystem_path(ecosystem_id, **params)
        url = "/api/ecosystems/#{ecosystem_id}/exercises"
        params.blank? ? url : "#{url}?#{params.to_query}"
      end

      it 'raises SecurityTransgression if user is anonymous or not a teacher' do
        page_ids = Content::Models::Page.all.map(&:id)

        expect do
          api_get exercises_api_ecosystem_path(ecosystem.id, page_ids: page_ids), nil
        end.to raise_error(SecurityTransgression)

        expect do
          api_get exercises_api_ecosystem_path(ecosystem.id, page_ids: page_ids), user_2_token
        end.to raise_error(SecurityTransgression)
      end

      it 'should return all exercises if page_ids is ommitted' do
        api_get exercises_api_ecosystem_path(ecosystem.id), user_1_token

        expect(response).to have_http_status(:success)
        expect(response.body_as_hash[:total_count]).to eq(ecosystem.exercises.size)
      end

      it 'works for teachers in the course' do
        page_ids = Content::Models::Page.all.map(&:id)
        api_get exercises_api_ecosystem_path(ecosystem.id, page_ids: page_ids), user_1_token

        expect(response).to have_http_status(:success)
        hash = response.body_as_hash
        expect(hash[:total_count]).to eq(168)
        hash[:items].each do |item|
          expect(item[:pool_types]).not_to be_empty
        end
      end

      it 'returns exercise exclusion information if a course_id is given' do
        page_ids = Content::Models::Page.all.map(&:id)
        api_get exercises_api_ecosystem_path(
          ecosystem.id, page_ids: page_ids, course_id: course.id
        ), user_1_token

        expect(response).to have_http_status(:success)
        hash = response.body_as_hash
        expect(hash[:total_count]).to eq(168)
        hash[:items].each do |item|
          expect(item[:is_excluded]).to eq false
        end
      end

      it 'returns only exercises in certain pools if pool_types are given' do
        page_ids = Content::Models::Page.all.map(&:id)
        api_get exercises_api_ecosystem_path(
          ecosystem.id, page_ids: page_ids, pool_types: 'homework_core'
        ), user_1_token

        expect(response).to have_http_status(:success)
        hash = response.body_as_hash
        expect(hash[:total_count]).to eq(
          ecosystem.exercises.count {|e| e.tags.detect { |t| t.value == 'assignment-type:homework' } }
        )
        hash[:items].each do |item|
          expect(item[:pool_types]).to eq ['homework_core']
        end
      end
    end

    context '#practice_exercises' do
      def exercises_api_ecosystem_path(ecosystem_id, **params)
        url = "/api/ecosystems/#{ecosystem_id}/practice_exercises"
        params.blank? ? url : "#{url}?#{params.to_query}"
      end

      it 'allows students to only see exercises that have been saved to practice' do
        exercise_ids = Content::Models::Exercise.all.map(&:id)
        exercise_id  = ecosystem.exercises.first.id
        FactoryBot.create(:tasks_practice_question,
                          role: student_role,
                          content_exercise_id: exercise_id)

        api_get exercises_api_ecosystem_path(
          ecosystem.id, course_id: course.id, exercise_ids: exercise_ids, role_id: student_role.id
        ), student_user_token

        hash = response.body_as_hash
        expect(hash[:total_count]).to eq(1)
        expect(hash[:items].first[:id]).to eq(exercise_id.to_s)

        # Ensure content_hash_for_student was used
        keys = hash[:items][0][:content][:questions][0][:answers].map(&:keys).flatten.uniq
        expect(keys.any?(:correctness)).to be false
      end
    end
  end
end
