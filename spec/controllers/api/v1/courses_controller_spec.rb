require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::CoursesController, type: :controller, api: true,
                                           version: :v1, vcr: VCR_OPTS, speed: :medium do

  before(:all) do
    @user_1 = FactoryBot.create :user
    @user_1_token = FactoryBot.create :doorkeeper_access_token, resource_owner_id: @user_1.id

    @user_2 = FactoryBot.create :user
    FactoryBot.create :doorkeeper_access_token, resource_owner_id: @user_2.id

    @userless_token = FactoryBot.create :doorkeeper_access_token

    @book = FactoryBot.create :content_book, :standard_contents_1
    @ecosystem = Content::Ecosystem.new strategy: @book.ecosystem.wrap
    @offering = FactoryBot.create :catalog_offering, ecosystem: @ecosystem.to_model

    @course = FactoryBot.create :course_profile_course,
                                offering: @offering, name: 'Physics 101', is_college: true
    @period = FactoryBot.create :course_membership_period, course: @course

    @zeroth_period = FactoryBot.create(:course_membership_period, course: @course, name: '0th')
    @zeroth_period.destroy!
  end

  context '#index' do
    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect { api_get :index, nil }.to raise_error(SecurityTransgression)
      end
    end

    context 'user is not in the course' do
      it 'returns nothing' do
        api_get :index, @user_1_token

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context 'user is a teacher or student in the course' do
      before { AddUserAsCourseTeacher.call course: @course, user: @user_1 }

      it 'includes all fields from the CourseRepresenter' do
        api_get :index, @user_1_token

        course_infos = CollectCourseInfo[user: @user_1]
        expect(response.body_as_hash).to match_array Api::V1::CoursesRepresenter.new(
          CollectCourseInfo[user: @user_1]
        ).as_json.map(&:deep_symbolize_keys)
      end
    end

    context 'user is a teacher' do
      let!(:teacher_role) { AddUserAsCourseTeacher[course: @course, user: @user_1] }

      it 'returns the teacher roles with the course' do
        api_get :index, @user_1_token

        expect(response.body_as_hash.first).to match a_hash_including(
          roles: a_collection_containing_exactly(
            id: teacher_role.id.to_s,
            research_identifier: teacher_role.research_identifier,
            type: 'teacher',
            joined_at: DateTimeUtilities.to_api_s(teacher_role.created_at)
          )
        )
      end
    end

    context 'user is a student' do
      let!(:student_role) { AddUserAsPeriodStudent[period: @period, user: @user_1] }

      it 'returns the student roles with the course' do
        api_get :index, @user_1_token

        expect(response.body_as_hash.first).to match a_hash_including(
          roles: a_collection_containing_exactly(
            id: student_role.id.to_s,
            research_identifier: student_role.research_identifier,
            type: 'student',
            period_id: @period.id.to_s,
            joined_at: DateTimeUtilities.to_api_s(student_role.created_at),
            latest_enrollment_at: DateTimeUtilities.to_api_s(student_role.latest_enrollment_at)
          ),
        )
      end
    end

    context 'user is both a teacher and student' do
      let!(:student_role) { AddUserAsPeriodStudent[period: @period, user: @user_1] }
      let!(:teacher_role) { AddUserAsCourseTeacher[course: @course, user: @user_1] }

      it 'returns both roles with the course' do
        api_get :index, @user_1_token

        expect(response.body_as_hash.first).to match a_hash_including(
          roles: a_collection_containing_exactly(
            {
              id: student_role.id.to_s,
              type: 'student',
              period_id: @period.id.to_s,
              research_identifier: student_role.research_identifier,
              joined_at: DateTimeUtilities.to_api_s(student_role.created_at),
              latest_enrollment_at: DateTimeUtilities.to_api_s(student_role.latest_enrollment_at)
            },
            {
              id: teacher_role.id.to_s,
              type: 'teacher',
              research_identifier: teacher_role.research_identifier,
              joined_at: DateTimeUtilities.to_api_s(teacher_role.created_at)
            }
          ),
        )
      end
    end
  end

  context '#create' do
    before(:all) do
      @term = TermYear::VISIBLE_TERMS.sample.to_s
      @year = Time.current.year
      @num_sections = 2
    end

    before                { allow(TrackTutorOnboardingEvent).to receive(:perform_later) }

    let(:valid_body_hash) do
      {
        name: 'A Course',
        term: @term,
        year: @year,
        is_preview: false,
        is_college: true,
        num_sections: @num_sections,
        offering_id: @offering.id.to_s
      }
    end
    let(:valid_body) { valid_body_hash.to_json }

    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect { api_post :create, nil, body: valid_body }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'normal user' do
      it 'raises SecurityTransgression' do
        expect { api_post :create, @user_1_token, body: valid_body }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'verified faculty' do
      before(:all) do
        DatabaseCleaner.start

        @user_1.account.confirmed_faculty!
        @user_1.account.college!

        @preview_course = CreateCourse.call(
          name: 'Unclaimed',
          term: @term,
          year: @year,
          time_zone: 'Indiana (East)',
          is_preview: true,
          is_college: true,
          is_test: false,
          num_sections: @num_sections,
          catalog_offering: @offering,
          estimated_student_count: 42
        ).outputs.course
        @preview_course.update_attribute :is_preview_ready, true
      end
      after(:all)  do
        DatabaseCleaner.clean

        @user_1.account.reload
      end

      context 'is_preview: true' do
        before { valid_body_hash[:is_preview] = true }

        it 'claims a preview course for the faculty if all required attributes are given' do
          valid_body_hash.delete(:term)
          valid_body_hash.delete(:year)
          expect do
            api_post :create, @user_1_token, body: valid_body
          end.not_to change { CourseProfile::Models::Course.count }

          expect(response).to have_http_status :success
          expect(response.body_as_hash).to match a_hash_including(valid_body_hash)
          expect(response.body_as_hash[:id]).to eq @preview_course.id.to_s
          expect(response.body_as_hash[:term]).to eq 'preview'
          expect(response.body_as_hash[:year]).to eq Time.current.year
        end

        it 'ignores the term and year attributes if given' do
          valid_body_hash.merge! year: 2016
          expect do
            api_post :create, @user_1_token, body: valid_body
          end.not_to change { CourseProfile::Models::Course.count }

          expect(response).to have_http_status :success
          expect(response.body_as_hash).to(
            match a_hash_including(valid_body_hash.except(:term, :year))
          )
          expect(response.body_as_hash[:id]).to eq @preview_course.id.to_s
          expect(response.body_as_hash[:term]).to eq 'preview'
          expect(response.body_as_hash[:year]).to eq Time.current.year
        end

        it 'makes the requesting faculty a teacher in the new preview course' do
          expect do
            api_post :create, @user_1_token, body: valid_body
          end.to change { CourseMembership::Models::Teacher.count }.by(1)

          expect(response).to have_http_status :success
          course = CourseProfile::Models::Course.order(:created_at).last
          expect(UserIsCourseTeacher[user: @user_1, course: course]).to eq true
        end
      end

      context 'is_preview: false' do
        it 'creates a new course for the faculty if all required attributes are given' do
          expect do
            api_post :create, @user_1_token, body: valid_body
          end.to change { CourseProfile::Models::Course.count }.by(1)

          expect(response).to have_http_status :success
          expect(response.body_as_hash).to match a_hash_including(valid_body_hash)
          expect(response.body_as_hash[:is_preview]).to eq false
        end

        it 'makes the requesting faculty a teacher in the new course' do
          expect do
            api_post :create, @user_1_token, body: valid_body
          end.to change { CourseMembership::Models::Teacher.count }.by(1)

          expect(response).to have_http_status :success
          course = CourseProfile::Models::Course.order(:created_at).last
          expect(UserIsCourseTeacher[user: @user_1, course: course]).to eq true
        end

        it 'requires the term and year attributes' do
          body_hash = valid_body_hash.except(:term, :year)
          expect do
            api_post :create, @user_1_token, body: body_hash.to_json
          end.not_to change { CourseMembership::Models::Teacher.count }

          expect(response).to have_http_status :unprocessable_entity
          expect(response.body_as_hash[:errors]).to include(
            {
              code: 'term_year_blank',
              message: 'You must specify the course term and year (except for preview courses)',
              data: nil
            }
          )
        end

        it 'does not allow the use of hidden course terms' do
          body_hash = valid_body_hash.merge term: :demo
          expect do
            api_post :create, @user_1_token, body: body_hash.to_json
          end.not_to change { CourseProfile::Models::Course.count }

          expect(response).to have_http_status :unprocessable_entity
          expect(response.body_as_hash[:errors]).to include(
            { code: 'invalid_term', message: 'The given course term is invalid' }
          )
        end
      end

      it 'returns errors if required attributes are not specified' do
        expect do
          api_post :create, @user_1_token
        end.not_to change { CourseProfile::Models::Course.count }

        expect(response).to have_http_status :unprocessable_entity
        expect(response.body_as_hash[:status]).to eq 422
        Api::V1::CoursesController::CREATE_REQUIRED_ATTRIBUTES.each do |required_attr|
          expect(response.body_as_hash[:errors]).to include(
            {code: "missing_attribute", message: "The #{required_attr} attribute must be provided"}
          )
        end
      end
    end
  end

  context '#show' do
    context 'course does not exist' do
      it 'raises RecordNotFound' do
        expect do
          api_get :show, nil, params: { id: -1 }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect do
          api_get :show, nil, params: { id: @course.id }
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'user is not in the course' do
      it 'raises SecurityTransgression' do
        expect do
          api_get :show, @user_1_token, params: { id: @course.id }
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'user is a teacher' do
      let!(:teacher_role) { AddUserAsCourseTeacher[course: @course, user: @user_1] }

      it 'returns the teacher roles with the course' do
        api_get :show, @user_1_token, params: { id: @course.id }

        expect(response.body_as_hash).to match a_hash_including(
          roles: a_collection_containing_exactly(
            id: teacher_role.id.to_s,
            research_identifier: teacher_role.research_identifier,
            type: 'teacher',
            joined_at: DateTimeUtilities.to_api_s(teacher_role.created_at)
          )
        )
      end
    end

    context 'user is a student' do
      let!(:student_role) { AddUserAsPeriodStudent[period: @period, user: @user_1] }

      it 'returns the student roles with the course' do
        api_get :show, @user_1_token, params: { id: @course.id }

        expect(response.body_as_hash).to match a_hash_including(
          roles: a_collection_containing_exactly(
            id: student_role.id.to_s,
            type: 'student',
            period_id: @period.id.to_s,
            research_identifier: student_role.research_identifier,
            joined_at: DateTimeUtilities.to_api_s(student_role.created_at),
            latest_enrollment_at: DateTimeUtilities.to_api_s(student_role.latest_enrollment_at)
          )
        )
      end
    end

    context 'user is both a teacher and student' do
      let!(:student_role) { AddUserAsPeriodStudent[period: @period, user: @user_1] }
      let!(:teacher_role) { AddUserAsCourseTeacher[course: @course, user: @user_1] }

      it 'returns both roles with the course' do
        api_get :show, @user_1_token, params: { id: @course.id }

        expect(response.body_as_hash).to match a_hash_including(
          roles: a_collection_containing_exactly(
            {
              id: student_role.id.to_s,
              type: 'student',
              period_id: @period.id.to_s,
              research_identifier: student_role.research_identifier,
              joined_at: DateTimeUtilities.to_api_s(student_role.created_at),
              latest_enrollment_at: DateTimeUtilities.to_api_s(student_role.latest_enrollment_at)
            },
            {
              id: teacher_role.id.to_s,
              type: 'teacher',
              research_identifier: teacher_role.research_identifier,
              joined_at: DateTimeUtilities.to_api_s(teacher_role.created_at)
            }
          )
        )
      end
    end
  end

  context '#update' do
    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect do
          api_patch :update, nil, params: { id: @course.id },
                                  body: { name: 'Renamed' }.to_json
        end.to raise_error(SecurityTransgression)

        expect(@course.reload.name).to eq 'Physics 101'
      end
    end

    context 'user is a student' do
      before do
        AddUserAsPeriodStudent.call(user: @user_1, period: @period)
      end

      it 'raises SecurityTrangression' do
        expect do
          api_patch :update, @user_1_token, params: { id: @course.id },
                                            body: { name: 'Renamed' }.to_json
        end.to raise_error(SecurityTransgression)

        expect(@course.reload.name).to eq 'Physics 101'
      end
    end

    context 'user is a teacher' do
      before { AddUserAsCourseTeacher.call(user: @user_1, course: @course) }

      it 'renames the course' do
        api_patch :update, @user_1_token, params: { id: @course.id },
                                          body: { name: 'Renamed' }.to_json

        expect(response.body_as_hash[:name]).to eq 'Renamed'
        expect(response.body_as_hash[:time_zone]).to eq 'Central Time (US & Canada)'
        expect(@course.reload.name).to eq 'Renamed'
        expect(@course.time_zone.name).to eq 'Central Time (US & Canada)'
      end

      it 'turns on LMS integration when allowed' do
        @course.update_attribute(:is_lms_enabling_allowed, true)
        api_patch :update, @user_1_token, params: { id: @course.id },
                                          body: { is_lms_enabled: true }.to_json

        expect(response.body_as_hash[:is_lms_enabled]).to eq true
        expect(@course.reload.is_lms_enabled).to eq true
      end

      it 'cannot turn on LMS integration when not allowed' do
        @course.update_attribute(:is_lms_enabling_allowed, false)
        api_patch :update, @user_1_token, params: { id: @course.id },
                                          body: { is_lms_enabled: true }.to_json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(@course.reload.is_lms_enabled).to eq nil
      end

      it 'updates the time_zone' do
        time_zone = @course.time_zone.to_tz
        opens_at = time_zone.now - 2.months
        due_at = time_zone.now + 2.months

        # User time-zone-less strings to update the open/due dates
        opens_at_str = opens_at.strftime "%Y-%m-%d %H:%M:%S"
        due_at_str = due_at.strftime "%Y-%m-%d %H:%M:%S"

        task_plan = FactoryBot.build :tasks_task_plan, owner: @course, num_tasking_plans: 0
        tasking_plan = FactoryBot.create :tasks_tasking_plan, task_plan: task_plan,
                                                               opens_at: opens_at_str,
                                                               due_at: due_at_str

        # The time zone is inferred from the course's TimeZone
        expect(tasking_plan.opens_at).to be_within(1).of(opens_at)
        expect(tasking_plan.due_at).to be_within(1).of(due_at)

        # Change course TimeZone to Edinburgh
        course_name = @course.name
        api_patch :update, @user_1_token, params: { id: @course.id },
                                          body: { name: course_name,
                                                           time_zone: 'Edinburgh' }.to_json

        expect(response.body_as_hash[:name]).to eq course_name
        expect(response.body_as_hash[:time_zone]).to eq 'Edinburgh'
        expect(@course.reload.name).to eq course_name
        expect(@course.time_zone.name).to eq 'Edinburgh'

        edinburgh_tz = @course.time_zone.to_tz

        # Reinterpret the time-zone-less strings as being in the Edingburgh time zone
        new_opens_at = edinburgh_tz.parse(opens_at_str)
        new_due_at = edinburgh_tz.parse(due_at_str)

        # The open/due dates changed
        expect(tasking_plan.reload.opens_at).not_to be_within(1).of(opens_at)
        expect(tasking_plan.due_at).not_to be_within(1).of(due_at)

        # They now act as if they were specified in the Edinburgh time zone
        expect(tasking_plan.opens_at).to be_within(1).of(new_opens_at)
        expect(tasking_plan.due_at).to be_within(1).of(new_due_at)
      end

      it 'updates the default open time' do
        course_name = @course.name
        api_patch :update, @user_1_token, params: { id: @course.id },
                                          body: { default_open_time: '01:02' }.to_json

        expect(response.body_as_hash[:name]).to eq course_name
        expect(response.body_as_hash[:time_zone]).to eq 'Central Time (US & Canada)'
        expect(response.body_as_hash[:default_open_time]).to eq '01:02'
        expect(@course.reload.name).to eq course_name
        expect(@course.time_zone.name).to eq 'Central Time (US & Canada)'
        expect(@course.default_open_time).to eq '01:02'
      end

      it 'freaks if the default open time is in a bad format' do
        expect do
          api_patch :update, @user_1_token,
                    params: { id: @course.id },
                    body: { default_open_time: '1pm' }.to_json
        end.not_to change{ @course.reload.default_open_time }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'updates the default due time' do
        course_name = @course.name
        api_patch :update, @user_1_token, params: { id: @course.id },
                                          body: { default_due_time: '02:02' }.to_json

        expect(@course.reload.name).to eq course_name
        expect(@course.time_zone.name).to eq 'Central Time (US & Canada)'
        expect(@course.reload.default_due_time).to eq '02:02'
        expect(response.body_as_hash[:name]).to eq course_name
        expect(response.body_as_hash[:time_zone]).to eq 'Central Time (US & Canada)'
        expect(response.body_as_hash[:default_due_time]).to eq '02:02'
      end

      it 'freaks if the default due time is in a bad format' do
        expect do
          api_patch :update, @user_1_token,
                    params: { id: @course.id },
                    body: { default_due_time: '1pm' }.to_json
        end.not_to change{ @course.reload.default_open_time }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'updates is_college' do
        expect(@course.is_college).to eq true
        api_patch :update, @user_1_token,
                  params: { id: @course.id },
                  body: { is_college: false }.to_json
        expect(@course.reload.is_college).to eq false
      end
    end
  end

  context '#dashboard' do
    before(:all) do
      DatabaseCleaner.start

      student_user = FactoryBot.create :user
      @student_role = AddUserAsPeriodStudent[user: student_user, period: @period]
      @student_token = FactoryBot.create :doorkeeper_access_token,
                                         resource_owner_id: student_user.id,
                                         expires_in: 1.year

      teacher_user = FactoryBot.create :user, first_name: 'Bob',
                                              last_name: 'Newhart',
                                              full_name: 'Bob Newhart'
      @teacher_role = AddUserAsCourseTeacher[user: teacher_user, course: @course]
      @teacher_token = FactoryBot.create :doorkeeper_access_token,
                                         resource_owner_id: teacher_user.id

      @time_zone = @course.time_zone.to_tz

      @reading_task = FactoryBot.create(
        :tasks_task, task_type: :reading,
                     opens_at: @time_zone.now - 1.week,
                     due_at: @time_zone.now,
                     step_types: [ :tasks_tasked_reading,
                                   :tasks_tasked_exercise,
                                   :tasks_tasked_exercise ],
                     tasked_to: @student_role
      )
      @hw1_task = FactoryBot.create(
        :tasks_task, task_type: :homework,
                     opens_at: @time_zone.now - 1.week,
                     due_at: @time_zone.now,
                     step_types: [ :tasks_tasked_exercise,
                                   :tasks_tasked_exercise,
                                   :tasks_tasked_exercise ],
                     tasked_to: @student_role
      )
      @hw2_task = FactoryBot.create(
        :tasks_task, task_type: :homework,
        opens_at: @time_zone.now - 1.week,
        due_at: @time_zone.now,
        step_types: [ :tasks_tasked_exercise,
                      :tasks_tasked_exercise,
                      :tasks_tasked_exercise ],
        tasked_to: @student_role
      )
      @hw3_task = FactoryBot.create(
        :tasks_task, task_type: :homework,
                     opens_at: @time_zone.now - 1.week,
                     due_at: @time_zone.now + 2.weeks,
                     step_types: [ :tasks_tasked_exercise,
                                   :tasks_tasked_exercise,
                                   :tasks_tasked_exercise ],
                     tasked_to: @student_role
      )
      @plan = FactoryBot.create(
        :tasks_task_plan, owner: @course,
                          published_at: @time_zone.now - 1.week,
                          publish_job_uuid: SecureRandom.uuid
      )
    end
    after(:all)  { DatabaseCleaner.clean }

    context 'anonymous' do
      it 'raises SecurityTransgression if user is anonymous or not in course' do
        expect do
          api_get :dashboard, nil, params: { id: @course.id }
        end.to raise_error(SecurityTransgression)

        expect do
          api_get :dashboard, @user_1_token, params: { id: @course.id }
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'not paid' do
      it "422's if needs to pay" do
        make_payment_required_and_expect_422(course: @course, student: @student_role.student) do
          api_get :dashboard, @student_token, params: { id: @course.id }
        end
      end
    end

    context 'student' do
      it 'returns an error if the course is a CC course' do
        @course.reload.update_attribute(:is_concept_coach, true)
        api_get :dashboard, @student_token, params: { id: @course.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'cc_course'
      end

      it "works without a role specified" do
        Preview::AnswerExercise[task_step: @hw1_task.task_steps[0], is_correct: true]
        Preview::AnswerExercise[task_step: @hw1_task.task_steps[2], is_correct: false]

        Preview::AnswerExercise[task_step: @hw2_task.task_steps[0], is_correct: true]
        Preview::AnswerExercise[task_step: @hw2_task.task_steps[1], is_correct: true]
        Preview::AnswerExercise[task_step: @hw2_task.task_steps[2], is_correct: false]

        Preview::AnswerExercise[task_step: @hw3_task.task_steps[0], is_correct: false]
        Preview::AnswerExercise[task_step: @hw3_task.task_steps[1], is_correct: false]
        Preview::AnswerExercise[task_step: @hw3_task.task_steps[2], is_correct: false]

        api_get :dashboard, @student_token, params: { id: @course.id }

        expect(response.body_as_hash).to match(
          tasks: a_collection_including(
            a_hash_including(
              id: @reading_task.id.to_s,
              title: @reading_task.title,
              opens_at: be_kind_of(String),
              due_at: be_kind_of(String),
              type: 'reading',
              complete: false,
              exercise_count: 2,
              complete_exercise_count: 0
            ),
            a_hash_including(
              id: @hw1_task.id.to_s,
              title: @hw1_task.title,
              opens_at: be_kind_of(String),
              due_at: be_kind_of(String),
              type: 'homework',
              complete: false,
              exercise_count: 3,
              complete_exercise_count: 2
            ),
            a_hash_including(
              id: @hw2_task.id.to_s,
              title: @hw2_task.title,
              opens_at: be_kind_of(String),
              due_at: be_kind_of(String),
              type: 'homework',
              complete: true,
              exercise_count: 3,
              complete_exercise_count: 3,
              correct_exercise_count: 2
            ),
            a_hash_including(
              id: @hw3_task.id.to_s,
              title: @hw3_task.title,
              opens_at: be_kind_of(String),
              due_at: be_kind_of(String),
              type: 'homework',
              complete: true,
              exercise_count: 3,
              complete_exercise_count: 3,
            )
          ),
          all_tasks_are_ready: true,
          role: {
            id: @student_role.id.to_s,
            type: 'student'
          },
          course: {
            name: 'Physics 101',
            teachers: [
              {
                id: @teacher_role.teacher.id.to_s,
                role_id: @teacher_role.id.to_s,
                first_name: 'Bob',
                last_name: 'Newhart'
              }
            ]
          }
        )
      end

      it "allows the start_at and end_at dates to be specified" do
        api_get :dashboard, @student_token, params: {
          id: @course.id, start_at: @time_zone.now + 1.day, end_at: @time_zone.now + 1.week
        }

        expect(response.body_as_hash[:tasks].size).to eq 1
      end

      it "allows the start_at date to be specified alone" do
        api_get :dashboard, @student_token, params: {
          id: @course.id, start_at: @time_zone.now + 1.day
        }

        expect(response.body_as_hash[:tasks].size).to eq 1
      end

      it "allows the end_at date to be specified alone" do
        api_get :dashboard, @student_token, params: {
          id: @course.id, end_at: @time_zone.now - 2.weeks
        }

        expect(response.body_as_hash[:tasks]).to be_empty
      end
    end

    context 'teacher' do
      it 'returns an error if the course is a CC course' do
        @course.reload.update_attribute :is_concept_coach, true
        api_get :dashboard, @teacher_token, params: { id: @course.id }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'cc_course'
      end

      it "works without a role specified" do
        api_get :dashboard, @teacher_token, params: { id: @course.id }

        expect(response.body_as_hash).to match(
          role: {
            id: @teacher_role.id.to_s,
            type: 'teacher'
          },
          course: {
            name: 'Physics 101',
            teachers: [
              {
                id: @teacher_role.teacher.id.to_s,
                role_id: @teacher_role.id.to_s,
                first_name: 'Bob',
                last_name: 'Newhart'
              }
            ]
          },
          tasks: [],
          all_tasks_are_ready: true,
          plans: a_collection_including(
            a_hash_including(
              id: @plan.id.to_s,
              type: 'reading',
              first_published_at: be_kind_of(String),
              last_published_at: be_kind_of(String),
              publish_job_url: be_kind_of(String),
              tasking_plans: [
                a_hash_including(
                  {
                    target_id: @course.id.to_s,
                    target_type: 'course',
                    opens_at: DateTimeUtilities.to_api_s(@plan.tasking_plans.first.opens_at),
                    due_at: DateTimeUtilities.to_api_s(@plan.tasking_plans.first.due_at)
                  }
                )
              ]
            )
          )
        )
      end

      it "allows the start_at and end_at dates to be specified" do
        api_get :dashboard, @teacher_token, params: {
          id: @course.id, start_at: @time_zone.now - 2.hours, end_at: @time_zone.now - 1.hour
        }

        expect(response.body_as_hash[:plans]).to be_empty
      end

      it "allows the start_at date to be specified alone" do
        api_get :dashboard, @teacher_token, params: {
          id: @course.id, start_at: @time_zone.now - 2.hours
        }

        expect(response.body_as_hash[:plans].size).to eq 1
      end

      it "allows the end_at date to be specified alone" do
        api_get :dashboard, @teacher_token, params: {
          id: @course.id, end_at: @time_zone.now - 1.hours
        }

        expect(response.body_as_hash[:plans]).to be_empty
      end
    end
  end

  context '#roster' do
    before(:all) do
      DatabaseCleaner.start

      @course.update_attribute :does_cost, true
      @period_2 = FactoryBot.create :course_membership_period, course: @course

      @student_user = FactoryBot.create :user
      @student_role = AddUserAsPeriodStudent[user: @student_user, period: @period]
      @student = @student_role.student
      @student_token = FactoryBot.create :doorkeeper_access_token,
                                         resource_owner_id: @student_user.id

      @student_user_2 = FactoryBot.create :user
      @student_role_2 = AddUserAsPeriodStudent[user: @student_user_2, period: @period]
      @student_2 = @student_role_2.student

      @student_user_3 = FactoryBot.create :user
      @student_role_3 = AddUserAsPeriodStudent[user: @student_user_3, period: @period_2]
      @student_3 = @student_role_3.student

      @teacher_user = FactoryBot.create :user, first_name: 'Bob',
                                               last_name: 'Newhart',
                                               full_name: 'Bob Newhart'
      @teacher_role = AddUserAsCourseTeacher[user: @teacher_user, course: @course]
      @teacher = @teacher_role.teacher
      @teacher_token = FactoryBot.create :doorkeeper_access_token,
                                         resource_owner_id: @teacher_user.id
    end
    after(:all)  do
      DatabaseCleaner.clean

      @course.reload
    end

    let(:valid_params) { { id: @course.id } }

    context 'caller has an authorization token' do
      context 'caller is a course teacher' do
        it 'returns the course roster' do
          allow(Settings::Payments).to receive(:payments_enabled) { true }

          @student_2.update_attribute :is_paid, true
          @student_3.update_attribute :is_comped, true

          api_get :roster, @teacher_token, params: valid_params
          expect(response).to have_http_status(:ok)
          roster = response.body_as_hash

          expect(roster).to include(
            teach_url: a_string_matching(/.*teach\/[a-f0-9]{32}\/DO_NOT.*/)
          )

          expect(roster).to include(
            teachers: a_collection_containing_exactly(
              id: @teacher_role.teacher.id.to_s,
              role_id: @teacher_role.id.to_s,
              first_name: @teacher_user.first_name,
              last_name: @teacher_user.last_name,
              is_active: true
            )
          )

          expect(roster).to include(
            students: a_collection_containing_exactly(
              a_hash_including(
                id: @student.id.to_s,
                first_name: @student_user.first_name,
                last_name: @student_user.last_name,
                name: @student_user.name,
                period_id: @period.id.to_s,
                role_id: @student_role.id.to_s,
                is_active: true,
                prompt_student_to_pay: true,
                is_paid: false,
                is_comped: false,
                payment_due_at: be_kind_of(String)
              ),
              a_hash_including(
                id: @student_2.id.to_s,
                first_name: @student_user_2.first_name,
                last_name: @student_user_2.last_name,
                name: @student_user_2.name,
                period_id: @period.id.to_s,
                role_id: @student_role_2.id.to_s,
                is_active: true,
                prompt_student_to_pay: false,
                is_paid: true,
                is_comped: false,
                payment_due_at: be_kind_of(String)
              ),
              a_hash_including(
                id: @student_3.id.to_s,
                first_name: @student_user_3.first_name,
                last_name: @student_user_3.last_name,
                name: @student_user_3.name,
                period_id: @period_2.id.to_s,
                role_id: @student_role_3.id.to_s,
                is_active: true,
                prompt_student_to_pay: false,
                is_paid: false,
                is_comped: true,
                payment_due_at: be_kind_of(String)
              )
            )
          )
        end
      end

      context 'caller is not a course teacher' do
        it 'raises SecurityTransgression' do
          expect do
            api_get :roster, @student_token, params: valid_params
          end.to raise_error(SecurityTransgression)
        end
      end
    end

    context 'caller has an application/client credentials authorization token' do
      it 'raises SecurityTransgression' do
        expect do
          api_get :roster, @userless_token, params: valid_params
        end.to raise_error(SecurityTransgression)
      end
    end

    context 'caller does not have an authorization token' do
      it 'raises SecurityTransgression' do
        expect do
          api_get :roster, nil, params: valid_params
        end.to raise_error(SecurityTransgression)
      end
    end
  end

  context '#clone' do
    let(:valid_params) { { id: @course.id               } }
    let(:valid_body)   { { copy_question_library: false } }

    before(:all) do
      DatabaseCleaner.start

      @course.update_attribute :is_preview, true
    end
    after(:all)  do
      DatabaseCleaner.clean

      @course.reload
    end

    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect { api_post :clone, nil, params: valid_params }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'user is not in the course' do
      it 'raises SecurityTransgression' do
        expect { api_post :clone, @user_1_token, params: valid_params }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'user is a student in the course' do
      before { AddUserAsPeriodStudent.call period: @period, user: @user_1 }

      it 'raises SecurityTransgression' do
        expect { api_post :clone, @user_1_token, params: valid_params }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'user is a teacher in the course' do
      let(:expected_year)      { @course.year + 1 }
      let(:expected_term_year) { TermYear.new(@course.term, expected_year) }
      let(:expected_response)  do
        Api::V1::CourseRepresenter.new(@course).as_json.deep_symbolize_keys.merge(
          id: a_kind_of(String),
          uuid: a_kind_of(String),
          year: expected_year,
          is_preview: false,
          starts_at: DateTimeUtilities.to_api_s(expected_term_year.starts_at),
          ends_at: DateTimeUtilities.to_api_s(expected_term_year.ends_at),
          is_active: be_in([true, false]),
          is_access_switchable: be_in([true, false]),
          periods: [a_kind_of(Hash)] * @course.num_sections,
          students: [],
          roles: [a_kind_of(Hash)],
          ecosystem_id: @course.offering.content_ecosystem_id.to_s,
          cloned_from_id: @course.id.to_s,
          does_cost: @course.offering.does_cost
        )
      end

      before { AddUserAsCourseTeacher.call course: @course, user: @user_1 }

      it 'clones the course for the user' do
        api_post :clone, @user_1_token, params: valid_params, body: valid_body

        expect(response).to have_http_status(:success)
        new_course = response.body_as_hash
        # the new course will have a different id and uuid
        expect(new_course[:id]).not_to eq(expected_response[:id])
        expect(new_course[:uuid]).not_to eq(expected_response[:uuid])
        # but will otherwise be the same
        expect(new_course).to match expected_response
      end
    end
  end

  context '#dates' do
    before(:all) do
      DatabaseCleaner.start

      10.times { FactoryBot.create :course_profile_course }
    end
    after(:all)  { DatabaseCleaner.clean }

    it 'displays an error message if the request is not valid JSON' do
      api_post :dates, nil, body: ''

      expect(response).to be_bad_request
      expect(response.body_as_hash[:errors].first[:message]).to(
        eq 'An empty string is not a valid JSON string.'
      )
    end

    it 'displays an error message if the request is not a JSON array' do
      api_post :dates, nil, body: { test: true }.to_json

      expect(response).to be_bad_request
      expect(response.body_as_hash[:errors].first[:message]).to(
        eq 'Request body must contain only a JSON array'
      )
    end

    it 'displays an error message if the request body JSON array does not contain strings' do
      api_post :dates, nil, body: [ { test: true } ].to_json

      expect(response).to be_bad_request
      expect(response.body_as_hash[:errors].first[:message]).to(
        eq 'Request body array elements must all be UUID strings'
      )
    end

    it 'returns a mapping from course UUIDs to start/end dates if the request is well-formatted' do
      courses = CourseProfile::Models::Course.last(3)

      api_post :dates, nil, body: courses.map(&:uuid).to_json

      expect(response).to be_ok
      courses.each do |course|
        expect(response.body_as_hash[course.uuid.to_sym]).to eq(
          starts_at: DateTimeUtilities.to_api_s(course.starts_at),
          ends_at: DateTimeUtilities.to_api_s(course.ends_at)
        )
      end
      expect(response.body_as_hash.size).to eq courses.size
    end
  end

end
