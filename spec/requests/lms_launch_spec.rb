require "rails_helper"

RSpec.describe 'LMS Launch', type: :request do

  let(:course) { FactoryGirl.create(:course_profile_course, is_lms_enabled: true) }
  let(:period) { FactoryGirl.create :course_membership_period, course: course }
  let(:lms_app) { FactoryGirl.create(:lms_app, owner: course) }
  let(:user) { FactoryGirl.create(:user) }

  let(:simulator) { Lms::Simulator.new(self) }
  let(:launch_helper) { Lms::LaunchHelper.new(self) }

  before(:each) {
    simulator.install_tutor(app: lms_app, course: "physics")
    simulator.set_launch_defaults(course: "physics")
  }

  context "student launches" do
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
    end
  end

  context "teacher launches" do
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
    simulator.add_administrator("admin")
    simulator.launch(user: "admin", assignment: "tutor")
    expect_error("only supports")
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
          expect_error("to see instructions for providing these fields")
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
          expect_error("to see instructions for providing these fields")
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
      expect_error("fail_lms_disabled")
    end

    it "errors if context doesn't exist yet" do
      course.update_attribute(:is_lms_enabled, false)

      simulator.launch(user: "user")
      expect_error("fail_lms_disabled")
    end
  end

  context "launch uses app keys already linked to another course" do
    # The 2nd launch will have a different LTI context_id (launching from a different
    # course but using the same LMS app, which we are prohibiting until we have
    # admin-setup of apps)

    it "gives an instructor-specific error" do
      simulator.add_teacher("teacher")
      simulator.launch(user: "teacher", course: "physics")
      launch_helper.complete_the_launch_locally

      simulator.install_tutor(app: lms_app, course: "biology")
      simulator.launch(user: "teacher", course: "biology")

      expect_error("Message for teachers")
    end

    it "gives a student-specific error" do
      simulator.add_student("student")
      simulator.launch(user: "student", course: "physics")
      launch_helper.complete_the_launch_locally

      simulator.install_tutor(app: lms_app, course: "biology")
      simulator.launch(user: "student", course: "biology")

      expect_error("Message for students")
    end
  end

  def expect_course_score_callback_count(user: user, count:)
    expect(Lms::Models::CourseScoreCallback.where(course: course).where(profile: user.to_model).count).to eq count
  end

  def expect_error(message, status_code=422)
    expect(response.status).to eq status_code
    expect(response.body.gsub("\n","")).to match /#{message}/
  end

end
