require "rails_helper"

RSpec.describe 'LMS Launch', type: :request do

  let(:course) { FactoryGirl.create(:course_profile_course, is_lms_enabled: true) }
  let(:period) { FactoryGirl.create :course_membership_period, course: course }
  let(:lms_app) { FactoryGirl.create(:lms_app, owner: course) }
  let(:user) { FactoryGirl.create(:user) }

  before(:each) { pretend_launch_signature_valid! }

  context "student launches" do
    context "not enrolled" do
      it 'redirects the student to enrollment' do
        expect_any_instance_of(Lms::Launch).to receive(:update_tool_consumer_metadata!)

        lr = FactoryGirl.build(:launch_request, :assignment, roles: :student, app: lms_app)
        post "/lms/launch", lr.request_parameters

        expect_and_fake_trip_to_accounts_and_back(user)

        expect(response.body).to match("/enroll/#{course.uuid}")
        expect(UserIsCourseStudent[course: course, user: user]).to eq false
        expect_course_grade_callback_count(1)
      end
    end

    context "already enrolled" do
      it 'redirects the student to course' do
        expect_any_instance_of(Lms::Launch).to receive(:update_tool_consumer_metadata!)

        AddUserAsPeriodStudent[period: period, user: user]

        lr = FactoryGirl.build(:launch_request, :assignment, roles: :student, app: lms_app)
        post "/lms/launch", lr.request_parameters

        expect_and_fake_trip_to_accounts_and_back(user)

        expect(response.body).to match("/course/#{course.id}")
        expect_course_grade_callback_count(1)
      end
    end
  end

  context "teacher launches" do
    context "not course teacher yet" do
      it 'makes the user a teacher and redirects to course' do
        expect_any_instance_of(Lms::Launch).to receive(:update_tool_consumer_metadata!)

        lr = FactoryGirl.build(:launch_request, :assignment, roles: :instructor, app: lms_app)
        post "/lms/launch", lr.request_parameters

        expect_and_fake_trip_to_accounts_and_back(user)

        expect(response.body).to match("/course/#{course.id}")
        expect(UserIsCourseTeacher[course: course, user: user]).to eq true
        expect_course_grade_callback_count(0)
      end
    end

    context "already a course teacher" do
      it 'redirects the user to the course' do
        expect_any_instance_of(Lms::Launch).to receive(:update_tool_consumer_metadata!)

        AddUserAsCourseTeacher[user: user, course: course]

        lr = FactoryGirl.build(:launch_request, :assignment, roles: :instructor, app: lms_app)
        post "/lms/launch", lr.request_parameters

        expect_and_fake_trip_to_accounts_and_back(user)

        expect(response.body).to match("/course/#{course.id}")
        expect(CourseMembership::Models::Teacher.count).to eq 1 # doesn't readd
      end
    end
  end

  it 'gives an error for unsupported role' do
    lr = FactoryGirl.build(:launch_request, roles: :administrator, app: lms_app)
    post "/lms/launch", lr.request_parameters
    expect_error("only supports")
  end

  context 'missing required fields' do
    context "tool_consumer_instance_guid" do
      let(:lr) { FactoryGirl.build(:launch_request, roles: role, app: lms_app,
                                    tool_consumer_instance_guid: nil) }

      context "teacher launch" do
        let(:role) { :instructor }

        it 'errors' do
          post "/lms/launch", lr.request_parameters
          expect_error("try to include the following fields.*tool_consumer_instance_guid")
        end
      end

      context "student launch" do
        let(:role) { :student }

        it 'errors' do
          post "/lms/launch", lr.request_parameters
          expect_error("to see instructions for providing these fields")
        end
      end
    end

    context "context_id" do
      let(:lr) { FactoryGirl.build(:launch_request, roles: role, app: lms_app, context_id: nil) }

      context "teacher launch" do
        let(:role) { :instructor }

        it 'errors' do
          post "/lms/launch", lr.request_parameters
          expect_error("try to include the following fields.*context_id")
        end
      end

      context "student launch" do
        let(:role) { :student }

        it 'errors' do
          post "/lms/launch", lr.request_parameters
          expect_error("to see instructions for providing these fields")
        end
      end
    end
  end

  context "lms disabled in course" do
    # test context existing or not because can hit this error on two different paths

    it "errors if context already exists" do
      run_new_launch(:assignment, roles: :instructor, app: lms_app) # builds context
      course.update_attribute(:is_lms_enabled, false)
      run_new_launch(:assignment, roles: :instructor, app: lms_app, go_to_accounts: false)
      expect_error("fail_lms_disabled")
    end

    it "errors if context doesn't exist yet" do
      course.update_attribute(:is_lms_enabled, false)
      run_new_launch(:assignment, roles: :instructor, app: lms_app, go_to_accounts: false)
      expect_error("fail_lms_disabled")
    end
  end

  context "launch uses app keys already linked to another course" do
    # The 2nd launch will have a different LTI context_id (launching from a different
    # course but using the same LMS app, which we are prohibiting until we have
    # admin-setup of apps)

    it "gives an instructor-specific error" do
      run_new_launch(:assignment, roles: :instructor, app: lms_app)
      run_new_launch(:assignment, roles: :instructor, app: lms_app, go_to_accounts: false)

      expect_error("Message for teachers")
    end

    it "gives a student-specific error" do
      run_new_launch(:assignment, roles: :student, app: lms_app)
      run_new_launch(:assignment, roles: :student, app: lms_app, go_to_accounts: false)

      expect_error("Message for students")
    end
  end

  def pretend_launch_signature_valid!
    allow(OpenStax::Accounts.configuration).to receive(:openstax_application_secret) { 'secret' }
    allow_any_instance_of(IMS::LTI::Services::MessageAuthenticator).to receive(:valid_signature?) { true }
  end

  def expect_and_fake_trip_to_accounts_and_back(user)
    expect(response.status).to eq 200
    get response.body.match(/href=\"(.*)\"/)[1] # 'click' open in new tab

    expect(redirect_path).to eq "/accounts/login"
    expect(redirect_query_hash[:sp]["signature"]).not_to be_blank

    stub_current_user(user)
    get redirect_query_hash[:return_to]
  end

  def expect_course_grade_callback_count(count)
    expect(Lms::Models::CourseGradeCallback.where(course: course).where(profile: user.to_model).count).to eq count
  end

  def run_new_launch(*args, **keyword_args)
    go_to_accounts = keyword_args.delete(:go_to_accounts)
    go_to_accounts = true if go_to_accounts.nil?

    lr = FactoryGirl.build(:launch_request, *args, **keyword_args)
    post "/lms/launch", lr.request_parameters
    expect_and_fake_trip_to_accounts_and_back(user) if go_to_accounts
    lr
  end

  def expect_error(message, status_code=422)
    expect(response.status).to eq status_code
    expect(response.body.gsub("\n","")).to match /#{message}/
  end

end
