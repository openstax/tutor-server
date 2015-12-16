require 'rails_helper'
require 'vcr_helper'

describe GetCcDashboard, type: :routine do

  before(:all) do
    DatabaseCleaner.start

    @course   = CreateCourse[name: 'Physics 101', is_concept_coach: true]
    @period   = CreatePeriod[course: @course]
    @period_2 = CreatePeriod[course: @course]

    @student_user = FactoryGirl.create(:user)
    @student_role = AddUserAsPeriodStudent[user: @student_user, period: @period]

    @student_user_2 = FactoryGirl.create(:user)
    @student_role_2 = AddUserAsPeriodStudent[user: @student_user_2, period: @period_2]

    @teacher_user = FactoryGirl.create(:user, first_name: 'Bob',
                                              last_name: 'Newhart',
                                              full_name: 'Bob Newhart')
    @teacher_role = AddUserAsCourseTeacher[user: @teacher_user, course: @course]

    @chapter = FactoryGirl.create :content_chapter, book_location: [4]
    cnx_page_1 = OpenStax::Cnx::V1::Page.new(id: '95e61258-2faf-41d4-af92-f62e1414175a',
                                             title: 'Force')
    cnx_page_2 = OpenStax::Cnx::V1::Page.new(id: '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6',
                                             title: "Newton's First Law of Motion: Inertia")
    book_location_1 = [4, 1]
    book_location_2 = [4, 2]

    page_model_1, page_model_2 = VCR.use_cassette('GetCcDashboard/with_book', VCR_OPTS) do
      [Content::Routines::ImportPage[chapter: @chapter,
                                     cnx_page: cnx_page_1,
                                     book_location: book_location_1],
       Content::Routines::ImportPage[chapter: @chapter,
                                     cnx_page: cnx_page_2,
                                     book_location: book_location_2]]
    end

    @book = @chapter.book
    Content::Routines::PopulateExercisePools[book: @book]

    @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
    @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)

    ecosystem_model = @book.ecosystem
    ecosystem = Content::Ecosystem.new(strategy: ecosystem_model.wrap)

    AddEcosystemToCourse[ecosystem: ecosystem, course: @course]
  end

  after(:all) { DatabaseCleaner.clean }

  context 'without any work' do
    it "still returns period info for teachers" do
      outputs = described_class.call(course: @course, role: @teacher_role).outputs

      expect(HashWithIndifferentAccess[outputs]).to include(
        course: {
          id: @course.id,
          name: "Physics 101",
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
      ].task
      @task_1.task_steps.each do |ts|
        Hacks::AnswerExercise[task_step: ts, is_correct: true]
      end
      @task_2 = GetConceptCoach[
        user: @student_user, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ].task
      @task_2.task_steps.each do |ts|
        Hacks::AnswerExercise[task_step: ts, is_correct: ts.core_group?]
      end
      @task_3 = GetConceptCoach[
        user: @student_user_2, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ].task
      @task_3.task_steps.select(&:core_group?).first(2).each_with_index do |ts, ii|
        Hacks::AnswerExercise[task_step: ts, is_correct: ii == 0]
      end
      @task_4 = GetConceptCoach[
        user: @student_user_2, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ].task
    end

    it "works for a student" do
      outputs = described_class.call(course: @course, role: @student_role).outputs

      expect(HashWithIndifferentAccess[outputs]).to include(
        course: {
          id: @course.id,
          name: "Physics 101",
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
          @task_1, @task_2
        ),
        chapters: [
          {
            id: @chapter.id,
            title: @chapter.title,
            book_location: @chapter.book_location,
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
                    is_correct: true
                  }
                end + Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
                        .map{ |k_ago, ex_count| ex_count }.reduce(:+).times.map do
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
          name: "Physics 101",
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
                  id: @chapter.id,
                  title: @chapter.title,
                  book_location: @chapter.book_location,
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
                      original_performance: 1.0,
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
                  id: @chapter.id,
                  title: @chapter.title,
                  book_location: @chapter.book_location,
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
      @student_role.student.inactivate.save!
      @student_role_2.student.inactivate.save!

      outputs = described_class.call(course: @course.reload, role: @teacher_role).outputs

      expect(HashWithIndifferentAccess[outputs]).to include(
        course: {
          id: @course.id,
          name: "Physics 101",
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
                  id: @chapter.id,
                  title: @chapter.title,
                  book_location: @chapter.book_location,
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
                      original_performance: 1.0,
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
                  id: @chapter.id,
                  title: @chapter.title,
                  book_location: @chapter.book_location,
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
      @period.to_model.taskings.first.task.task.tasked_exercises.first.task_step
             .update_attribute(:last_completed_at, Time.now)

      # Miss (4 times = 4 counts per period * 1 period)
      described_class[course: @course, role: @teacher_role]
      expect(@counts).to eq 12
    end
  end
end
