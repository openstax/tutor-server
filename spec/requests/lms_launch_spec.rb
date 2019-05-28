require "rails_helper"

RSpec.describe 'LMS Launch', type: :request do

  let(:course)  { FactoryBot.create(:course_profile_course, is_lms_enabled: true) }
  let(:period)  { FactoryBot.create :course_membership_period, course: course }
  let(:lms_app) { FactoryBot.create(:lms_app, owner: course) }
  let(:user)    { FactoryBot.create(:user) }

  let(:simulator)     { Lms::Simulator.new(self) }
  let(:launch_helper) { Lms::LaunchHelper.new(self) }

  before(:each) do
    simulator.install_tutor(app: lms_app, course: "physics")
    simulator.set_launch_defaults(course: "physics")
  end

  context "student launches" do

    context "not yet paired" do
      it 'displays message about unconfigured course' do
        simulator.install_tutor(app: Lms::WilloLabs.new, course: "physics")
        simulator.set_launch_defaults(course: "physics")
        simulator.add_student("bob")
        simulator.launch(user: "bob", assignment: "tutor")
        expect(response.body).to match 'course is not yet configured'
      end
    end

    context "not enrolled" do
      it 'redirects the student to enrollment' do
        expect_any_instance_of(Lms::Launch).to receive(:update_tool_consumer_metadata!)
        simulator.add_student("bob")
        simulator.launch(user: "bob", assignment: "tutor")
        bob_user = launch_helper.complete_the_launch_locally

        expect(response.body).to match("/enroll/#{course.uuid}")
        expect(UserIsCourseStudent[course: course, user: user]).to eq false


        expect_course_score_callback_count(user: bob_user, count: 1)
      end
    end

    context "already enrolled" do
      it 'redirects the student to course' do
        # Launch once so we know about bob in all places, which is what would happen anyway
        simulator.add_student("bob")
        simulator.launch(user: "bob", assignment: "tutor")
        bob_user = launch_helper.complete_the_launch_locally

        AddUserAsPeriodStudent[period: period, user: bob_user]

        simulator.launch(user: "bob", assignment: "tutor")
        bob_user = launch_helper.complete_the_launch_locally

        expect(response.body).to match("/course/#{course.id}")
        expect_course_score_callback_count(user: bob_user, count: 1)
      end

      it 'errors for course score callback in use' do
        expect(UserIsCourseStudent).to receive(:[]).and_return(true)
        simulator.reuse_sourcedids!
        FactoryBot.create :lms_course_score_callback,
                               result_sourcedid: simulator.sourcedid!(
                                 user: "bob", assignment: "tutor"
                               ),
                               outcome_url: simulator.outcome_url,
                               course: course
        simulator.add_student("bob")
        simulator.launch(user: "bob", assignment: "tutor")
        launch_helper.complete_the_launch_locally
        expect_error("already been used for a registration")
      end

      it 'complains about reused launch nonce' do
        expect(Raven).to receive(:capture_message).with(/Attempt to reuse nonce/)
        simulator.add_student("bob")
        simulator.launch(user: "bob", assignment: "tutor")
        simulator.repeat_last_launch
        expect_error("Please contact support@openstax.org")
      end
    end

    context "dropped" do
      it 'redirects the student to the course, not enrollment' do
        simulator.add_student("bob")
        simulator.launch(user: "bob", assignment: "tutor")
        bob_user = launch_helper.complete_the_launch_locally

        student = AddUserAsPeriodStudent[period: period, user: bob_user].student
        CourseMembership::InactivateStudent[student: student]
        simulator.launch(user: "bob", assignment: "tutor")
        launch_helper.complete_the_launch_locally

        expect(response.body).to match("/course/#{course.id}")
      end
    end
  end

  context "teacher launches" do

    context "not yet paired" do
      it 'displays message about unconfigured course' do
        simulator.install_tutor(app: Lms::WilloLabs.new, course: "physics")
        simulator.set_launch_defaults(course: "physics")
        simulator.add_teacher("teacher")
        simulator.launch(user: "teacher", assignment: "tutor")
        launch_helper.complete_the_launch_locally

        launch_helper.pair_launch_to_course

      end
    end

    context "not course teacher yet" do
      it 'makes the user a teacher and redirects to course' do
        expect_any_instance_of(Lms::Launch).to receive(:update_tool_consumer_metadata!)

        simulator.add_teacher("teacher")
        simulator.launch(user: "teacher", assignment: "tutor")
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

        simulator.add_teacher("teacher")
        simulator.launch(user: "teacher", assignment: "tutor")
        teacher_user = launch_helper.complete_the_launch_locally(log_in_as: user)

        expect(response.body).to match("/course/#{course.id}")
        expect(CourseMembership::Models::Teacher.count).to eq 1 # doesn't readd
      end
    end
  end

  it 'gives an error for unsupported role' do
    params = simulator.launch(
      user: "bob", assignment: "tutor",
    )
    expect_error("Only the course instructor and enrolled")
  end

  it 'errors for invalid keys' do
    simulator.install_tutor(key: "bad", secret: "wrong", course: "other")
    simulator.add_teacher("teacher")
    simulator.launch(user: "teacher", assignment: "tutor", course: "other")
    expect_error("may not have been integrated correctly")
  end

  context 'missing required fields' do
    context "tool_consumer_instance_guid" do
      context "teacher launch" do
        before(:each) { simulator.add_teacher("teacher") }

        it 'errors' do
          simulator.launch(user: "teacher", drop_these_fields: :tool_consumer_instance_guid)
          expect_error("try to include the following fields.*tool_consumer_instance_guid")
        end
      end

      context "student launch" do
        before(:each) { simulator.add_student("student") }

        it 'errors' do
          simulator.launch(user: "student", drop_these_fields: :tool_consumer_instance_guid)
          expect_error("may not have been integrated correctly")
        end
      end
    end

    context "context_id" do
      context "teacher launch" do
        before(:each) { simulator.add_teacher("teacher") }

        it 'errors' do
          simulator.launch(user: "teacher", drop_these_fields: :context_id)
          expect_error("try to include the following fields.*context_id")
        end
      end

      context "student launch" do
        before(:each) { simulator.add_student("student") }

        it 'errors' do
          simulator.launch(user: "student", drop_these_fields: :context_id)
          expect_error("not have been integrated correctly")
        end
      end
    end
  end

  context "lms disabled in course" do
    # test context existing or not because can hit this error on two different paths
    before(:each) { simulator.add_teacher("user") }

    it "errors if context already exists" do
      # launch once to build context
      simulator.launch(user: "user")
      launch_helper.complete_the_launch_locally

      course.update_attribute(:is_lms_enabled, false)
      simulator.launch(user: "user")
      expect_error("teacher launches are also disabled")
    end

    it "errors if context doesn't exist yet" do
      course.update_attribute(:is_lms_enabled, false)

      simulator.launch(user: "user")
      expect_error("teacher launches are also disabled")
    end
  end

  context "launch using app keys already linked to another course" do

    it "succeeds without errors" do
      simulator.add_teacher("teacher")
      simulator.launch(user: "teacher", course: "physics")

      teacher_user = launch_helper.complete_the_launch_locally
      expect(response.body).to match("/course/#{course.id}")
      expect(UserIsCourseTeacher[course: course, user: teacher_user]).to eq true
      expect_course_score_callback_count(user: teacher_user, count: 0)
    end

  end

  context "LMS changes sourcedid on each launch" do
    before(:each) { simulator.do_not_reuse_sourcedids! }

    it "only keeps one per link / user combo" do
      simulator.add_student("bob")
      simulator.launch(user: "bob", assignment: "tutor")
      bob_user = launch_helper.complete_the_launch_locally

      AddUserAsPeriodStudent[period: period, user: bob_user]

      callbacks = callbacks(bob_user)
      expect(callbacks.count).to eq 1
      first_sourcedid = callbacks.first.result_sourcedid

      simulator.launch(user: "bob", assignment: "tutor")
      bob_user = launch_helper.complete_the_launch_locally

      callbacks = callbacks(bob_user)
      expect(callbacks.count).to eq 1
      expect(callbacks.first.result_sourcedid).not_to eq first_sourcedid

      simulator.launch(user: "bob", assignment: "other_tutor_assignment")
      bob_user = launch_helper.complete_the_launch_locally

      callbacks = callbacks(bob_user)
      expect(callbacks.count).to eq 2
    end
  end

  context "LMS reuses sourcedid on each launch" do
    it "only keeps one per link / user combo" do
      simulator.add_student("bob")
      simulator.launch(user: "bob", assignment: "tutor")
      bob_user = launch_helper.complete_the_launch_locally

      AddUserAsPeriodStudent[period: period, user: bob_user]

      callbacks = callbacks(bob_user)
      expect(callbacks.count).to eq 1
      first_sourcedid = callbacks.first.result_sourcedid

      simulator.launch(user: "bob", assignment: "tutor")
      bob_user = launch_helper.complete_the_launch_locally

      callbacks = callbacks(bob_user)
      expect(callbacks.count).to eq 1
      expect(callbacks.first.result_sourcedid).to eq first_sourcedid

      simulator.launch(user: "bob", assignment: "other_tutor_assignment")
      bob_user = launch_helper.complete_the_launch_locally

      callbacks = callbacks(bob_user)
      expect(callbacks.count).to eq 2
      expect(callbacks.map(&:result_sourcedid).uniq.length).to eq 2
    end
  end

  def expect_course_score_callback_count(user:, count:)
    expect(Lms::Models::CourseScoreCallback.where(course: course).where(profile: user.to_model).count).to eq count
  end

  def callbacks(user)
    Lms::Models::CourseScoreCallback.where(course: course).where(profile: user.to_model)
  end

  def expect_error(message, status_code=422)
#    expect(response.status).to eq status_code
    expect(response.body.gsub("\n","")).to match /#{message}/
  end

end
