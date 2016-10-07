require 'rails_helper'

RSpec.describe "Students in archived old period sign up in new term",
               type: :request, api: true, version: :v1 do

  # Basic flow of what we want to show:
  #   import book
  #   create course
  #   associate book to course
  #   create a period
  #   sign up a student
  #   have student do two CC's
  #   archive the period
  #   student signs up again for new period
  #   show history clear (by itself, hard to do since GetHistory takes a role
  #                       which is where we go wrong)
  #   student works a CC
  #   show scores report has one column with value
  #   student works another CC
  #   show my progress API endpoint has two tasks

  context "CC course" do

    before(:all) do
      @course = FactoryGirl.create :entity_course, is_concept_coach: true
      semester_1_period = FactoryGirl.create :course_membership_period, course: @course

      @student_user = FactoryGirl.create(:user)

      teacher_user = FactoryGirl.create(:user)
      teacher_role = AddUserAsCourseTeacher[user: teacher_user, course: @course]
      teacher = teacher_role.teacher

      application = FactoryGirl.create :doorkeeper_application
      @teacher_token =  FactoryGirl.create :doorkeeper_access_token,
                                           application: application,
                                           resource_owner_id: teacher_user.id
      @student_token =  FactoryGirl.create :doorkeeper_access_token,
                                           application: application,
                                           resource_owner_id: @student_user.id

      @book = FactoryGirl.create :content_book, :standard_contents_2
      ecosystem = Content::Ecosystem.new(strategy: @book.ecosystem.wrap)

      # Associate the book to the course and make sure each page has 1 cc exercise
      CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: ecosystem)
      add_a_cc_exercise_to_each_page(@book)

      # Enroll the student and have him work 2 CC tasks
      enroll_cc_student(
        student_token: @student_token,
        enrollment_code: semester_1_period.enrollment_code,
        book_uuid: @book.uuid
      )

      cc_task_sem_1_page_0 = GetConceptCoach[
        user: @student_user, cnx_book_id: @book.uuid, cnx_page_id: @book.pages[0].uuid
      ]
      Demo::AnswerExercise[task_step: cc_task_sem_1_page_0.task_steps[0], is_correct: true]

      cc_task_sem_1_page_1 = GetConceptCoach[
        user: @student_user, cnx_book_id: @book.uuid, cnx_page_id: @book.pages[1].uuid
      ]
      Demo::AnswerExercise[task_step: cc_task_sem_1_page_1.task_steps[0], is_correct: true]

      # teacher, preparing to teach this course again in the current approach,
      # archives the period she has and makes a new one
      semester_1_period.to_model.destroy!
      semester_2_period = FactoryGirl.create :course_membership_period, course: @course

      # the same student user signs up for the next semester in the same course
      # (maybe he failed or dropped in the first semester)
      enroll_cc_student(
        student_token: @student_token,
        enrollment_code: semester_2_period.enrollment_code,
        book_uuid: @book.uuid
      )
    end

    it 'lets the student work a CC from scratch that he did in the first semester' do
      cc_task_sem_2_page_0 = GetConceptCoach[
        user: @student_user, cnx_book_id: @book.uuid, cnx_page_id: @book.pages[0].uuid
      ]
      expect(cc_task_sem_2_page_0).not_to be_completed
    end

    context 'student dashboard' do
      it 'shows no work initially' do
        # "My Progress" screen pulls data from the CC dashboard endpoint
        api_get("/api/courses/#{@course.id}/cc/dashboard", @student_token)
        expect(response.body_as_hash[:tasks].size).to eq 0
      end

      it 'shows only and all 2nd semester CCs' do
        cc_task_sem_2_page_2 = GetConceptCoach[
          user: @student_user, cnx_book_id: @book.uuid, cnx_page_id: @book.pages[2].uuid
        ]
        Demo::AnswerExercise[task_step: cc_task_sem_2_page_2.task_steps[0], is_correct: true]

        cc_task_sem_2_page_3 = GetConceptCoach[
          user: @student_user, cnx_book_id: @book.uuid, cnx_page_id: @book.pages[3].uuid
        ]
        Demo::AnswerExercise[task_step: cc_task_sem_2_page_3.task_steps[0], is_correct: true]

        # "My Progress" screen pulls data from the CC dashboard endpoint
        api_get("/api/courses/#{@course.id}/cc/dashboard", @student_token)
        expect(response.body_as_hash[:tasks].size).to eq 2
      end
    end

    context 'teacher scores report' do
      it 'shows no work initially' do
        api_get("/api/courses/#{@course.id}/performance", @teacher_token)

        expect(response.body_as_hash[0][:data_headings].size).to eq 0
        expect(response.body_as_hash[0][:students][0][:data].size).to eq 0
      end

      it 'shows only and all the 2nd semester CCs' do
        cc_task_sem_2_page_2 = GetConceptCoach[
          user: @student_user, cnx_book_id: @book.uuid, cnx_page_id: @book.pages[2].uuid
        ]
        Demo::AnswerExercise[task_step: cc_task_sem_2_page_2.task_steps[0], is_correct: true]

        api_get("/api/courses/#{@course.id}/performance", @teacher_token)

        expect(response.body_as_hash[0][:data_headings].size).to eq 1
        expect(response.body_as_hash[0][:students][0][:data].size).to eq 1
      end
    end

  end

  protected

  def add_a_cc_exercise_to_each_page(book)
    book.pages.each do |page|
      exercise = FactoryGirl.create(:content_exercise)
      cc_pool = page.concept_coach_pool
      cc_pool.content_exercise_ids = [exercise.id]
      cc_pool.save!
    end
  end

  def enroll_cc_student(student_token:, enrollment_code:, book_uuid:)
    api_post(api_enrollment_changes_path,
             student_token,
             raw_post_data: {
               enrollment_code: enrollment_code, book_uuid: book_uuid
             }.to_json)

    expect(response).to have_http_status(:created)
    enrollment_change_id = response.body_as_hash[:id]

    api_put(approve_api_enrollment_change_path(id: enrollment_change_id), student_token)
    expect(response).to have_http_status(:success)
  end

end
