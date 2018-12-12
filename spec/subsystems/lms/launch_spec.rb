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
