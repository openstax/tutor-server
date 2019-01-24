require 'rails_helper'

RSpec.describe Lms::Launch do

  let(:course) { FactoryBot.create :course_profile_course, is_lms_enabled: true }
  let(:app) { FactoryBot.create(:lms_app, owner: course) }
  let(:message) {
    OpenStruct.new(context_id: '1234', tool_consumer_instance_guid: '4242')
  }
  let(:authenticator) {
    OpenStruct.new(:valid_signature? => true, message: message)
  }

  describe 'duplicated CourseScoreCallback records' do
    let(:launch) { Lms::Launch.from_request(
                     FactoryBot.create(:launch_request, :assignment,
                                       app: app, course: course),
                     authenticator: authenticator) }

    let(:dupe) { FactoryBot.create :lms_course_score_callback,
                                   result_sourcedid: launch.result_sourcedid,
                                   outcome_url: launch.outcome_url,
                                   course: course }
    it 'removes unattached ones' do
      launch.store_score_callback(dupe.profile)
      expect { dupe.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it 'fails if dupe is in use' do
      expect(UserIsCourseStudent).to receive(:[]).and_return(true)
      expect {
        launch.store_score_callback(dupe.profile)
      }.to raise_error Lms::Launch::CourseScoreInUse
    end
  end

  it 'creates context' do
    launch = Lms::Launch.from_request(
      FactoryBot.create(:launch_request, app: app),
      authenticator: authenticator
    )
    expect {
      launch.persist!
    }.to change { Lms::Models::Context.count }.by 1
    expect(launch.context).not_to be_nil
  end

  it 'verifies nonce unused' do
    request = FactoryBot.create(:launch_request, app: app)
    Lms::Launch.from_request(request, authenticator: authenticator)
    expect { Lms::Launch.from_request(request) }.to raise_error(Lms::Launch::AlreadyUsed)
  end

  it 'maps roles' do
      { instructor: %w{Instructor Creator Faculty Mentor Staff SysAdmin SysSupport AccountAdmin Administrator},
        student: %w{Student Learner ProspectiveStudent}
      }.each do |role, mappings|
          mappings.each do |type|
              req = FactoryBot.create(:launch_request, app: app)
              req.request_parameters[:roles] = "IMS::LIS::Roles::Context::URNs::#{type}"
              launch = Lms::Launch.from_request(req,authenticator: authenticator)
              expect(launch.role).to eq role
          end
      end
  end

  it 'multiple concurrent contexts without course can be launched' do
    app = Lms::WilloLabs.new
    3.times do |i|
      expect {
        message.context_id = "launch-#{i}"
        launch = Lms::Launch.from_request(
          FactoryBot.create(:launch_request, app: app),
          authenticator: authenticator
        )
        launch.persist!
      }.to change { Lms::Models::Context.count }.by 1
    end
  end
end
