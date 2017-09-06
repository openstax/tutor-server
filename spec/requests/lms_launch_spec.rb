require "rails_helper"

RSpec.describe 'LMS Launch', type: :request do

  let(:period) { FactoryGirl.create :course_membership_period }
  let(:lms_app) { FactoryGirl.create(:lms_app, owner: course) }
  let(:user) { FactoryGirl.create(:user) }
  let(:course) { period.course }

  before(:each) { pretend_launch_signature_valid! }

  context 'unsupported role' do
    xit 'gives a 403' do
    end
  end

  context "LTI context unknown" do
    context "student launches" do
      context "not enrolled" do
        it 'redirects the student to enrollment' do
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
          AddUserAsCourseTeacher[user: user, course: course]

          lr = FactoryGirl.build(:launch_request, :assignment, roles: :instructor, app: lms_app)
          post "/lms/launch", lr.request_parameters

          expect_and_fake_trip_to_accounts_and_back(user)

          expect(response.body).to match("/course/#{course.id}")
          expect(CourseMembership::Models::Teacher.count).to eq 1 # doesn't readd
        end
      end
    end
  end

  context "LTI context known" do
    context "student launches" do

    end

    context "teacher launches" do

    end
  end

  context "admin installs LTI app" do
    xit "gives an error page that this is not yet supported" do
    end
  end

  def pretend_launch_signature_valid!
    allow(OpenStax::Accounts.configuration).to receive(:openstax_application_secret) { 'secret' }
    allow_any_instance_of(IMS::LTI::Services::MessageAuthenticator).to receive(:valid_signature?) { true }
  end

  def expect_and_fake_trip_to_accounts_and_back(user)
    expect(redirect_path).to eq "/accounts/login"
    expect(redirect_query_hash[:sp]["signature"]).not_to be_blank

    stub_current_user(user)
    get redirect_query_hash[:return_to]
  end

  def expect_course_grade_callback_count(count)
    expect(Lms::Models::CourseGradeCallback.where(course: course).where(profile: user.to_model).count).to eq count
  end

end
