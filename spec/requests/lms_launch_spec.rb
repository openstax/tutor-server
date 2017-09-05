require "rails_helper"

RSpec.describe 'LMS Launch', type: :request do

  let(:lms_app) { FactoryGirl.create(:lms_app) }
  before(:each) { pretend_launch_signature_valid! }
  let(:user)        { FactoryGirl.create(:user) }
  let(:course) { lms_app.owner }

  context 'unsupported role' do
    it 'gives a 403' do
    end
  end

  context "LTI context unknown" do
    context "student launches" do

      it 'redirects the student to an error page' do
        lr = FactoryGirl.build(:launch_request, roles: :student, app: lms_app)
        post "/lms/launch", lr.request_parameters

        expect(redirect_path).to eq "/accounts/login"
        expect(redirect_query_hash[:sp]["signature"]).not_to be_blank

        stub_current_user(user)
        get redirect_query_hash[:return_to]

        expect(UserIsCourseStudent[course: course, user: user]).to eq true
        expect(redirect_path).to eq course_dashboard_url(course)
      end
    end

    context "teacher launches" do

    end
  end

  context "LTI context known" do
    context "student launches" do

    end

    context "teacher launches" do

    end
  end

  def pretend_launch_signature_valid!
    allow(OpenStax::Accounts.configuration).to receive(:openstax_application_secret) { 'secret' }
    allow_any_instance_of(IMS::LTI::Services::MessageAuthenticator).to receive(:valid_signature?) { true }
  end

end
