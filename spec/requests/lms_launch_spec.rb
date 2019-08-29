require "rails_helper"

RSpec.describe 'LMS Launch', type: :request do

  let(:course)        { FactoryBot.create(:course_profile_course, is_lms_enabled: true) }
  let(:period)        { FactoryBot.create :course_membership_period, course: course }
  let(:lms_app)       { FactoryBot.create(:lms_app, owner: course) }
  let(:willo_labs)    { Lms::WilloLabs.new }
  let(:user)          { FactoryBot.create(:user) }

  let(:simulator)     { Lms::Simulator.new(self) }
  let(:launch_helper) { Lms::LaunchHelper.new(self) }

  let(:course_name)   { 'physics' }
  let(:username)      { 'bob' }
  let(:assignment)    { 'tutor' }

  before do
    simulator.install_tutor app: lms_app, course: course_name
    simulator.set_launch_defaults course: course_name, user: username, assignment: assignment
  end

  context "student launches" do
    before { simulator.add_student username }

    context "not yet paired (WilloLabs)" do
      before { simulator.install_tutor app: willo_labs, course: course_name }

      it 'displays message about unconfigured course' do
        simulator.launch
        expect(response.body).to match 'course is not yet configured'
      end
    end

    context "not enrolled" do
      it 'redirects the student to enrollment' do
        expect_any_instance_of(Lms::Launch).to receive(:update_tool_consumer_metadata!)
        simulator.launch
        student_user = launch_helper.complete_the_launch_locally

        expect(response.body).to match("/enroll/#{course.uuid}")
        expect(UserIsCourseStudent[course: course, user: student_user]).to eq false

        expect_course_score_callback_count(user: student_user, count: 1)
      end
    end

    context "already enrolled" do
      it 'redirects the student to course' do
        # Launch once so we know about bob in all places, which is what would happen anyway
        simulator.launch
        student_user = launch_helper.complete_the_launch_locally

        AddUserAsPeriodStudent[period: period, user: student_user]

        simulator.launch
        student_user = launch_helper.complete_the_launch_locally

        expect(response.body).to match("/course/#{course.id}")
        expect_course_score_callback_count(user: student_user, count: 1)
      end

      context 'course score callback in use' do
        it 'errors' do
          expect(UserIsCourseStudent).to receive(:[]).and_return(true)
          simulator.reuse_sourcedids!
          FactoryBot.create :lms_course_score_callback,
                                 result_sourcedid: simulator.sourcedid!(
                                   user: "bob", assignment: "tutor"
                                 ),
                                 outcome_url: simulator.outcome_url,
                                 course: course
          simulator.launch
          launch_helper.complete_the_launch_locally
          expect_error("already been used for a registration")
        end
      end
    end

    context "dropped" do
      it 'redirects the student to the course, not enrollment' do
        simulator.launch
        student_user = launch_helper.complete_the_launch_locally

        student = AddUserAsPeriodStudent[period: period, user: student_user].student
        CourseMembership::InactivateStudent[student: student]

        simulator.launch
        launch_helper.complete_the_launch_locally
        expect(response.body).to match("/course/#{course.id}")
      end
    end

    context 'app not found' do
      before { simulator.install_tutor(key: 'bad', secret: 'wrong', course: course_name) }

      it 'errors' do
        simulator.launch
        expect_error("may not have been integrated correctly")
      end
    end

    context 'invalid signature' do
      before { simulator.install_tutor key: lms_app.key, secret: 'wrong', course: course_name }

      it 'errors' do
        simulator.launch
        expect_error("may not have been integrated correctly")
      end
    end

    context 'expired timestamp' do
      let(:request_params) do
        Timecop.travel(Time.current - 2 * Lms::Launch::MAX_REQUEST_AGE) { simulator.launch_params }
      end

      it 'errors' do
        post '/lms/launch', params: request_params
        expect_error("request has expired")
      end
    end

    context 'invalid timestamp' do
      let(:request_params) do
        Timecop.travel(Time.current + 2 * Lms::Launch::MAX_REQUEST_AGE) { simulator.launch_params }
      end

      it 'errors' do
        post '/lms/launch', params: request_params
        expect_error("too far into the future")
      end
    end

    context 'nonce already used' do
      it 'errors' do
        simulator.launch
        simulator.repeat_last_launch
        expect_error("duplicate request")
      end
    end

    context "course ended" do
      before do
        # this error does not happen with WilloLabs because
        simulator.install_tutor(app: lms_app, course: course_name)
        course.update_attribute(:ends_at, Time.current)
      end

      it "errors" do
        simulator.launch
        expect_error("course has already ended")
      end
    end

    context "lms disabled in course" do
      # test context existing or not because can hit this error on two different paths
      it "errors if context already exists" do
        # launch once to build context
        simulator.launch
        launch_helper.complete_the_launch_locally

        course.update_attribute(:is_lms_enabled, false)
        simulator.launch
        expect_error("use the course enrollment link provided by your instructor")
      end

      it "errors if context doesn't exist yet" do
        course.update_attribute(:is_lms_enabled, false)

        simulator.launch
        expect_error("use the course enrollment link provided by your instructor")
      end
    end

    context 'missing required fields' do
      context "tool_consumer_instance_guid" do
        it 'errors' do
          simulator.launch drop_these_fields: :tool_consumer_instance_guid
          expect_error("may not have been integrated correctly")
        end
      end

      context "context_id" do
        it 'errors' do
          simulator.launch drop_these_fields: :context_id
          expect_error("may not have been integrated correctly")
        end
      end
    end

    context "launch using app keys already linked to another course" do
      # The 2nd launch will have a different LTI context_id
      # (launching from a different course but using the same LMS app)

      it "succeeds without errors" do
        simulator.launch
        student_user = launch_helper.complete_the_launch_locally

        expect(response.body).to match("/enroll/#{course.uuid}")
        expect(UserIsCourseStudent[course: course, user: student_user]).to eq false
        expect_course_score_callback_count(user: student_user, count: 1)

        simulator.install_tutor app: lms_app, course: 'biology'
        simulator.launch course: 'biology'
        student_user = launch_helper.complete_the_launch_locally

        expect(response.body).to match("/enroll/#{course.uuid}")
        expect(UserIsCourseStudent[course: course, user: student_user]).to eq false
        expect_course_score_callback_count(user: student_user, count: 1)
      end
    end

    context "LMS changes sourcedid on each launch" do
      before(:each) { simulator.do_not_reuse_sourcedids! }

      it "only keeps one per link / user combo" do
        simulator.launch
        student_user = launch_helper.complete_the_launch_locally

        AddUserAsPeriodStudent[period: period, user: student_user]

        callbacks = callbacks(student_user)
        expect(callbacks.count).to eq 1
        first_sourcedid = callbacks.first.result_sourcedid

        simulator.launch
        student_user = launch_helper.complete_the_launch_locally

        callbacks = callbacks(student_user)
        expect(callbacks.count).to eq 1
        expect(callbacks.first.result_sourcedid).not_to eq first_sourcedid

        simulator.launch assignment: 'other_tutor_assignment'
        student_user = launch_helper.complete_the_launch_locally

        callbacks = callbacks(student_user)
        expect(callbacks.count).to eq 2
      end
    end

    context "LMS reuses sourcedid on each launch" do
      it "only keeps one per link / user combo" do
        simulator.launch
        student_user = launch_helper.complete_the_launch_locally

        AddUserAsPeriodStudent[period: period, user: student_user]

        callbacks = callbacks(student_user)
        expect(callbacks.count).to eq 1
        first_sourcedid = callbacks.first.result_sourcedid

        simulator.launch
        student_user = launch_helper.complete_the_launch_locally

        callbacks = callbacks(student_user)
        expect(callbacks.count).to eq 1
        expect(callbacks.first.result_sourcedid).to eq first_sourcedid

        simulator.launch assignment: 'other_tutor_assignment'
        student_user = launch_helper.complete_the_launch_locally

        callbacks = callbacks(student_user)
        expect(callbacks.count).to eq 2
        expect(callbacks.map(&:result_sourcedid).uniq.length).to eq 2
      end
    end
  end

  context "teacher launches" do
    before { simulator.add_teacher username }

    context "not yet paired (WilloLabs)" do
      before { simulator.install_tutor app: willo_labs, course: course_name }

      it 'displays message about unconfigured course' do
        simulator.launch
        launch_helper.complete_the_launch_locally

        launch_helper.pair_launch_to_course
      end
    end

    context "not course teacher yet" do
      it 'makes the user a teacher and redirects to course' do
        expect_any_instance_of(Lms::Launch).to receive(:update_tool_consumer_metadata!)

        simulator.launch
        teacher_user = launch_helper.complete_the_launch_locally

        expect(response.body).to match("/course/#{course.id}")
        expect(UserIsCourseTeacher[course: course, user: teacher_user]).to eq true
        expect_course_score_callback_count(user: teacher_user, count: 0)
      end
    end

    context "already a course teacher" do
      it 'redirects the user to the course' do
        expect_any_instance_of(Lms::Launch).to receive(:update_tool_consumer_metadata!)

        AddUserAsCourseTeacher[user: user, course: course]

        simulator.launch
        teacher_user = launch_helper.complete_the_launch_locally(log_in_as: user)

        expect(response.body).to match("/course/#{course.id}")
        expect(CourseMembership::Models::Teacher.count).to eq 1 # doesn't readd
      end
    end

    context 'app not found' do
      before { simulator.install_tutor(key: 'bad', secret: 'wrong', course: course_name) }

      it 'errors' do
        simulator.launch
        expect_error("key you entered does not match")
      end
    end

    context 'invalid signature' do
      before { simulator.install_tutor key: lms_app.key, secret: 'wrong', course: course_name }

      it 'errors' do
        simulator.launch
        expect_error("secret may not match")
      end
    end

    context 'expired timestamp' do
      let(:request_params) do
        Timecop.travel(Time.current - 2 * Lms::Launch::MAX_REQUEST_AGE) { simulator.launch_params }
      end

      it 'errors' do
        post '/lms/launch', params: request_params
        expect_error("LMS sent us an expired request")
      end
    end

    context 'invalid timestamp' do
      let(:request_params) do
        Timecop.travel(Time.current + 2 * Lms::Launch::MAX_REQUEST_AGE) { simulator.launch_params }
      end

      it 'errors' do
        post '/lms/launch', params: request_params
        expect_error("LMS sent us a request that is too far into the future")
      end
    end

    context 'nonce already used' do
      it 'errors' do
        simulator.launch
        simulator.repeat_last_launch
        expect_error("duplicate request")
      end
    end

    context "course ended" do
      before { course.update_attribute(:ends_at, Time.current) }

      it "errors" do
        simulator.launch
        expect_error("course has already ended")
      end
    end

    context "lms disabled in course" do
      # test context existing or not because can hit this error on two different paths
      it "errors if context already exists" do
        # launch once to build context
        simulator.launch
        launch_helper.complete_the_launch_locally

        course.update_attribute(:is_lms_enabled, false)
        simulator.launch
        expect_error("teacher launches are also disabled")
      end

      it "errors if context doesn't exist yet" do
        course.update_attribute(:is_lms_enabled, false)

        simulator.launch
        expect_error("teacher launches are also disabled")
      end
    end

    context 'missing required fields' do
      context "tool_consumer_instance_guid" do
        it 'errors' do
          simulator.launch drop_these_fields: :tool_consumer_instance_guid
          expect_error("try to include the following fields.*tool_consumer_instance_guid")
        end
      end

      context "context_id" do
        it 'errors' do
          simulator.launch drop_these_fields: :context_id
          expect_error("try to include the following fields.*context_id")
        end
      end
    end

    context "launch using app keys already linked to another course" do
      # The 2nd launch will have a different LTI context_id
      # (launching from a different course but using the same LMS app)

      it "succeeds without errors" do
        simulator.launch
        teacher_user = launch_helper.complete_the_launch_locally

        expect(response.body).to match("/course/#{course.id}")
        expect(UserIsCourseTeacher[course: course, user: teacher_user]).to eq true
        expect_course_score_callback_count(user: teacher_user, count: 0)

        simulator.install_tutor app: lms_app, course: 'biology'
        simulator.launch course: 'biology'
        teacher_user = launch_helper.complete_the_launch_locally

        expect(response.body).to match("/course/#{course.id}")
        expect(UserIsCourseTeacher[course: course, user: teacher_user]).to eq true
        expect_course_score_callback_count(user: teacher_user, count: 0)
      end
    end

    context "LMS changes sourcedid on each launch" do
      before(:each) { simulator.do_not_reuse_sourcedids! }

      it "does not use LMS sourcedids" do
        simulator.launch
        teacher_user = launch_helper.complete_the_launch_locally

        AddUserAsPeriodStudent[period: period, user: teacher_user]

        callbacks = callbacks(teacher_user)
        expect(callbacks.count).to eq 0

        simulator.launch
        teacher_user = launch_helper.complete_the_launch_locally

        callbacks = callbacks(teacher_user)
        expect(callbacks.count).to eq 0

        simulator.launch assignment: 'other_tutor_assignment'
        teacher_user = launch_helper.complete_the_launch_locally

        callbacks = callbacks(teacher_user)
        expect(callbacks.count).to eq 0
      end
    end

    context "LMS reuses sourcedid on each launch" do
      it "does not use LMS sourcedids" do
        simulator.launch
        teacher_user = launch_helper.complete_the_launch_locally

        AddUserAsPeriodStudent[period: period, user: teacher_user]

        callbacks = callbacks(teacher_user)
        expect(callbacks.count).to eq 0

        simulator.launch
        teacher_user = launch_helper.complete_the_launch_locally

        callbacks = callbacks(teacher_user)
        expect(callbacks.count).to eq 0

        simulator.launch assignment: 'other_tutor_assignment'
        teacher_user = launch_helper.complete_the_launch_locally

        callbacks = callbacks(teacher_user)
        expect(callbacks.count).to eq 0
      end
    end
  end

  context 'neither student nor teacher' do
    it 'gives an error for unsupported role' do
      params = simulator.launch
      expect_error("Only the course instructor and enrolled")
    end
  end

  context "could not load launch" do
    before do
      simulator.install_tutor(app: lms_app, course: course_name, launch_path: launch_path)
    end

    context "launch_authenticate" do
      let(:launch_path) { '/lms/launch_authenticate' }

      it "errors" do
        simulator.launch method: :get
        expect_error("Make sure your browser is set to allow cookies from OpenStax Tutor")
      end
    end

    context "complete_launch" do
      let(:launch_path) { '/lms/complete_launch' }

      it "errors" do
        simulator.launch method: :get
        expect(response).to redirect_to Regexp.new(openstax_accounts.login_url)

        stub_current_user(user)
        simulator.launch method: :get
        expect_error("Make sure your browser is set to allow cookies from OpenStax Tutor")
      end
    end
  end

  def expect_course_score_callback_count(user:, count:)
    expect(Lms::Models::CourseScoreCallback.where(course: course).where(profile: user.to_model).count).to eq count
  end

  def callbacks(user)
    Lms::Models::CourseScoreCallback.where(course: course).where(profile: user.to_model)
  end

  def expect_error(message, status_code=422)
#   expect(response.status).to eq status_code
    expect(response.body.gsub("\n","")).to match /#{message}/
  end

end
