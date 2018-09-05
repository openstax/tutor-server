require 'rails_helper'

RSpec.describe Lms::PairLaunchToCourse do

  let(:course) { FactoryBot.create :course_profile_course }

  it "sets errors when launch doesn't exist" do
    result = subject.call(launch_id: 123, course: course)
    expect(result.outputs.success).to be false
    expect(result.errors).not_to be_empty
    expect(result.errors.first.code).to eq :lms_launch_doesnt_exist
  end

  it "pairs launch to a course" do
    app = Lms::WilloLabs.new
    expect_any_instance_of(
      ::IMS::LTI::Services::MessageAuthenticator
    ).to receive(:valid_signature?).and_return(true)

    launch = Lms::Launch.from_request(
      FactoryBot.create(:launch_request, app: app)
    )
    launch.attempt_context_creation
    result = subject.call(launch_id: launch.persist!, course: course)
    expect(result.outputs.success).to be true
    expect(result.errors).to be_empty
    expect(course.reload.is_lms_enabled).to be true
  end
end
