require 'rails_helper'

RSpec.describe Lms::Launch do

  let(:course) { FactoryBot.create :course_profile_course, is_lms_enabled: true }
  let(:app) { FactoryBot.create(:lms_app, owner: course) }

  it 'creates context' do
    expect_any_instance_of(
      ::IMS::LTI::Services::MessageAuthenticator
    ).to receive(:valid_signature?).and_return(true)

    launch = Lms::Launch.from_request(
      FactoryBot.create(:launch_request, app: app)
    )
    expect {
      launch.persist!
    }.to change { Lms::Models::Context.count }.by 1
    expect(launch.context).not_to be_nil
  end

  it 'verifies nonce unused' do
    expect_any_instance_of(
      ::IMS::LTI::Services::MessageAuthenticator
    ).to receive(:valid_signature?).and_return(true)
    request = FactoryBot.create(:launch_request, app: app)
    Lms::Launch.from_request(request)
    expect { Lms::Launch.from_request(request) }.to raise_error(Lms::Launch::AlreadyUsed)
  end
end
