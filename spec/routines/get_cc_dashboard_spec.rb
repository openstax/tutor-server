require 'rails_helper'
require 'vcr_helper'

RSpec.describe GetCcDashboard, type: :routine do

  before(:all) do
    @course   = FactoryGirl.create :course_profile_course, is_concept_coach: true, name: 'Biology 101'
    @period   = FactoryGirl.create :course_membership_period, course: @course
    @period_2 = FactoryGirl.create :course_membership_period, course: @course

    @student_user = FactoryGirl.create(:user)
    @student_role = AddUserAsPeriodStudent[user: @student_user, period: @period]

    @student_user_2 = FactoryGirl.create(:user)
    @student_role_2 = AddUserAsPeriodStudent[user: @student_user_2, period: @period_2]

    @teacher_user = FactoryGirl.create(:user, first_name: 'Bob',
                                              last_name: 'Newhart',
                                              full_name: 'Bob Newhart')
    @teacher_role = AddUserAsCourseTeacher[user: @teacher_user, course: @course]

    @book = FactoryGirl.create :content_book
    @chapter_1 = FactoryGirl.create :content_chapter, book: @book, book_location: [1]
    @chapter_2 = FactoryGirl.create :content_chapter, book: @book, book_location: [2]
    cnx_page_1 = OpenStax::Cnx::V1::Page.new(id: 'ad9b9d37-a5cf-4a0d-b8c1-083fcc4d3b0c',
                                             title: 'Sample module 1')
    cnx_page_2 = OpenStax::Cnx::V1::Page.new(id: '6a0568d8-23d7-439b-9a01-16e4e73886b3',
                                             title: 'The Science of Biology')
    cnx_page_3 = OpenStax::Cnx::V1::Page.new(id: '7636a3bf-eb80-4898-8b2c-e81c1711b99f',
                                             title: 'Sample module 2')
    book_location_1 = [1, 1]
    book_location_2 = [1, 2]
    book_location_3 = [2, 1]

    page_model_1, page_model_2, page_model_3 = \
      VCR.use_cassette('GetCcDashboard/with_pages', VCR_OPTS) do
        OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/') do
          [Content::Routines::ImportPage[chapter: @chapter_1,
                                         cnx_page: cnx_page_1,
                                         book_location: book_location_1],
           Content::Routines::ImportPage[chapter: @chapter_1,
                                         cnx_page: cnx_page_2,
                                         book_location: book_location_2],
           Content::Routines::ImportPage[chapter: @chapter_2,
                                         cnx_page: cnx_page_3,
                                         book_location: book_location_3]]
        end
      end

    Content::Routines::PopulateExercisePools[book: @book]

    @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
    @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)
    @page_3 = Content::Page.new(strategy: page_model_3.reload.wrap)

    ecosystem_model = @book.ecosystem
    ecosystem = Content::Ecosystem.new(strategy: ecosystem_model.wrap)

    AddEcosystemToCourse[ecosystem: ecosystem, course: @course]
  end

  context 'without any work' do
    it "still returns period info for teachers" do
      outputs = described_class.call(course: @course, role: @teacher_role).outputs

      expect(HashWithIndifferentAccess[outputs]).to include(
        course: {
          id: @course.id,
          name: 'Biology 101',
          teachers: [
            {
              id: @teacher_role.teacher.id.to_s,
              role_id: @teacher_role.id.to_s,
              first_name: 'Bob',
              last_name: 'Newhart'
            }
          ],
          periods: a_collection_containing_exactly(
            {
              id: @period.id,
              name: @period.name,
              chapters: []
            },
            {
              id: @period_2.id,
              name: @period_2.name,
              chapters: []
            }
          )
        },
        role: {
          id: @teacher_role.id,
          type: 'teacher'
        },
        tasks: []
      )
    end
  end

  context 'with work' do
    before(:each) do
      @task_1 = GetConceptCoach[
        user: @student_user, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ]
      @task_1.task_steps.each do |ts|
        Demo::AnswerExercise[task_step: ts, is_correct: true]
      end
      @task_2 = GetConceptCoach[
        user: @student_user, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ]
      @task_2.task_steps.each do |ts|
        Demo::AnswerExercise[task_step: ts, is_correct: false]
      end
      @task_3 = GetConceptCoach[
        user: @student_user, cnx_book_id: @book.uuid, cnx_page_id: @page_3.uuid
      ]
      @task_3.task_steps.each do |ts|
        Demo::AnswerExercise[task_step: ts, is_correct: ts.core_group?]
      end
      @task_4 = GetConceptCoach[
        user: @student_user_2, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ]
      @task_4.task_steps.select(&:core_group?).first(2).each_with_index do |ts, ii|
        Demo::AnswerExercise[task_step: ts, is_correct: ii == 0]
      end
      @task_5 = GetConceptCoach[
        user: @student_user_2, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ]
    end

    it "works for a student" do
      outputs = described_class.call(course: @course, role: @student_role).outputs

      expect(HashWithIndifferentAccess[outputs]).to include(
        course: {
          id: @course.id,
          name: 'Biology 101',
          teachers: [
            { id: @teacher_role.teacher.id.to_s,
              role_id: @teacher_role.id.to_s,
              first_name: 'Bob',
              last_name: 'Newhart' }
          ]
        },
        role: {
          id: @student_role.id,
          type: 'student'
        },
        tasks: a_collection_including(
          @task_1, @task_2, @task_3
        ),
        chapters: [
          {
            id: @chapter_2.id,
            title: @chapter_2.title,
            book_location: @chapter_2.book_location,
            pages: [
              {
                id: @page_3.id,
                title: @page_3.title,
                uuid: @page_3.uuid,
                version: @page_3.version,
                book_location: @page_3.book_location,
                last_worked_at: a_kind_of(Time),
                exercises: Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT.times.map do
                  {
                    id: a_kind_of(Integer),
                    is_completed: true,
                    is_correct: true
                  }
                end + Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
                        .select{ |k_ago, ex_count| k_ago != :random && k_ago <= 2 }
                        .map{ |k_ago, ex_count| ex_count }.reduce(0, :+).times.map do
                  {
                    id: a_kind_of(Integer),
                    is_completed: true,
                    is_correct: false
                  }
                end
              }
            ]
          },
          {
            id: @chapter_1.id,
            title: @chapter_1.title,
            book_location: @chapter_1.book_location,
            pages: [
              {
                id: @page_2.id,
                title: @page_2.title,
                uuid: @page_2.uuid,
                version: @page_2.version,
                book_location: @page_2.book_location,
                last_worked_at: a_kind_of(Time),
                exercises: Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT.times.map do
                  {
                    id: a_kind_of(Integer),
                    is_completed: true,
                    is_correct: false
                  }
                end
              },
              {
                id: @page_1.id,
                title: @page_1.title,
                uuid: @page_1.uuid,
                version: @page_1.version,
                book_location: @page_1.book_location,
                last_worked_at: a_kind_of(Time),
                exercises: Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT.times.map do
                  {
                    id: a_kind_of(Integer),
                    is_completed: true,
                    is_correct: true
                  }
                end
              }
            ]
          }
        ]
      )
    end

    it "works for a teacher" do
      outputs = described_class.call(course: @course, role: @teacher_role).outputs

      expect(HashWithIndifferentAccess[outputs]).to include(
        course: {
          id: @course.id,
          name: 'Biology 101',
          teachers: [
            {
              id: @teacher_role.teacher.id.to_s,
              role_id: @teacher_role.id.to_s,
              first_name: 'Bob',
              last_name: 'Newhart'
            }
          ],
          periods: a_collection_containing_exactly(
            {
              id: @period.id,
              name: @period.name,
              chapters: [
                {
                  id: @chapter_2.id,
                  title: @chapter_2.title,
                  book_location: @chapter_2.book_location,
                  pages: [
                    {
                      id: @page_3.id,
                      title: @page_3.title,
                      uuid: @page_3.uuid,
                      version: @page_3.version,
                      book_location: @page_3.book_location,
                      completed: 1,
                      in_progress: 0,
                      not_started: 0,
                      original_performance: 1.0,
                      spaced_practice_performance: nil
                    }
                  ]
                },
                {
                  id: @chapter_1.id,
                  title: @chapter_1.title,
                  book_location: @chapter_1.book_location,
                  pages: [
                    {
                      id: @page_2.id,
                      title: @page_2.title,
                      uuid: @page_2.uuid,
                      version: @page_2.version,
                      book_location: @page_2.book_location,
                      completed: 1,
                      in_progress: 0,
                      not_started: 0,
                      original_performance: 0.0,
                      spaced_practice_performance: nil
                    },
                    {
                      id: @page_1.id,
                      title: @page_1.title,
                      uuid: @page_1.uuid,
                      version: @page_1.version,
                      book_location: @page_1.book_location,
                      completed: 1,
                      in_progress: 0,
                      not_started: 0,
                      original_performance: 1.0,
                      spaced_practice_performance: 0.0
                    }
                  ]
                }
              ]
            },
            {
              id: @period_2.id,
              name: @period_2.name,
              chapters: [
                {
                  id: @chapter_1.id,
                  title: @chapter_1.title,
                  book_location: @chapter_1.book_location,
                  pages: [
                    {
                      id: @page_1.id,
                      title: @page_1.title,
                      uuid: @page_1.uuid,
                      version: @page_1.version,
                      book_location: @page_1.book_location,
                      completed: 0,
                      in_progress: 1,
                      not_started: 0,
                      original_performance: 0.5,
                      spaced_practice_performance: nil
                    }
                  ]
                }
              ]
            }
          )
        },
        role: {
          id: @teacher_role.id,
          type: 'teacher'
        },
        tasks: []
      )
    end

    it "does not return negative numbers if a student starts/finishes a task and then drops" do
      @student_role.student.destroy
      @student_role_2.student.destroy
      @course.reload

      outputs = described_class.call(course: @course, role: @teacher_role).outputs

      expect(HashWithIndifferentAccess[outputs]).to include(
        course: {
          id: @course.id,
          name: 'Biology 101',
          teachers: [
            {
              id: @teacher_role.teacher.id.to_s,
              role_id: @teacher_role.id.to_s,
              first_name: 'Bob',
              last_name: 'Newhart'
            }
          ],
          periods: a_collection_containing_exactly(
            {
              id: @period.id,
              name: @period.name,
              chapters: [
                {
                  id: @chapter_2.id,
                  title: @chapter_2.title,
                  book_location: @chapter_2.book_location,
                  pages: [
                    {
                      id: @page_3.id,
                      title: @page_3.title,
                      uuid: @page_3.uuid,
                      version: @page_3.version,
                      book_location: @page_3.book_location,
                      completed: 1,
                      in_progress: 0,
                      not_started: 0,
                      original_performance: 1.0,
                      spaced_practice_performance: nil
                    }
                  ]
                },
                {
                  id: @chapter_1.id,
                  title: @chapter_1.title,
                  book_location: @chapter_1.book_location,
                  pages: [
                    {
                      id: @page_2.id,
                      title: @page_2.title,
                      uuid: @page_2.uuid,
                      version: @page_2.version,
                      book_location: @page_2.book_location,
                      completed: 1,
                      in_progress: 0,
                      not_started: 0,
                      original_performance: 0.0,
                      spaced_practice_performance: nil
                    },
                    {
                      id: @page_1.id,
                      title: @page_1.title,
                      uuid: @page_1.uuid,
                      version: @page_1.version,
                      book_location: @page_1.book_location,
                      completed: 1,
                      in_progress: 0,
                      not_started: 0,
                      original_performance: 1.0,
                      spaced_practice_performance: 0.0
                    }
                  ]
                }
              ]
            },
            {
              id: @period_2.id,
              name: @period_2.name,
              chapters: [
                {
                  id: @chapter_1.id,
                  title: @chapter_1.title,
                  book_location: @chapter_1.book_location,
                  pages: [
                    {
                      id: @page_1.id,
                      title: @page_1.title,
                      uuid: @page_1.uuid,
                      version: @page_1.version,
                      book_location: @page_1.book_location,
                      completed: 0,
                      in_progress: 1,
                      not_started: 0,
                      original_performance: 0.5,
                      spaced_practice_performance: nil
                    }
                  ]
                }
              ]
            }
          )
        },
        role: {
          id: @teacher_role.id,
          type: 'teacher'
        },
        tasks: []
      )
    end

    it 'caches recent teacher dashboard results' do
      @counts = 0
      allow_any_instance_of(Tasks::Models::TaskedExercise::ActiveRecord_Relation).to(
        receive(:count).with('DISTINCT tasks_tasked_exercises.id') { @counts += 1 }
      )

      # Miss (8 times = 4 counts per period * 2 periods)
      described_class[course: @course, role: @teacher_role]
      expect(@counts).to eq 8

      # Hit
      described_class[course: @course, role: @teacher_role]
      expect(@counts).to eq 8

      teacher_user_2 = FactoryGirl.create(:user)
      teacher_role_2 = AddUserAsCourseTeacher.call(user: teacher_user_2, course: @course)
                                             .outputs.role

      # Hit
      described_class[course: @course, role: teacher_role_2]
      expect(@counts).to eq 8

      # Answering an exercise invalidates the period cache
      @period.to_model.taskings.first.task.tasked_exercises.first.task_step
             .update_attribute(:last_completed_at, Time.current)

      # Miss (4 times = 4 counts per period * 1 period)
      described_class[course: @course, role: @teacher_role]
      expect(@counts).to eq 12
    end
  end
end
