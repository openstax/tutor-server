require 'rails_helper'

RSpec.describe Lms::PairLaunchToCourse do

  let(:course) { FactoryBot.create :course_profile_course }
  let(:message) {
    OpenStruct.new(context_id: '1234', tool_consumer_instance_guid: '4242')
  }
  let(:authenticator) {
    OpenStruct.new(:valid_signature? => true, message: message)
  }

  it "sets errors when launch doesn't exist" do
    result = subject.call(launch_id: 123, course: course)
    expect(result.outputs.success).to be false
    expect(result.errors).not_to be_empty
    expect(result.errors.first.code).to eq :lms_launch_doesnt_exist
  end

  it "pairs launch to a course" do
    app = Lms::WilloLabs.new
    launch = Lms::Launch.from_request(
      FactoryBot.create(:launch_request, app: app),
      authenticator: authenticator
    )
    result = subject.call(launch_id: launch.persist!, course: course)
    expect(result.outputs.success).to be true
    expect(result.errors).to be_empty
    expect(course.reload.is_lms_enabled).to be true
  end
end
