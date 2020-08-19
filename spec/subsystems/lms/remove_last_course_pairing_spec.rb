require 'rails_helper'

RSpec.describe Lms::RemoveLastCoursePairing do

  let(:message) {
    OpenStruct.new(context_id: '1234', tool_consumer_instance_guid: '4242')
  }
  let(:authenticator) {
    OpenStruct.new(:valid_signature? => true, message: message)
  }
  let(:launch) {
    Lms::Launch.from_request(
      FactoryBot.create(:launch_request, app: Lms::WilloLabs.new),
      authenticator: authenticator
    ).validate!
  }
  let(:course) { FactoryBot.create :course_profile_course }

  before(:each) {
    Lms::PairLaunchToCourse.call(launch_uuid: launch.persist!, course: course)
    course.reload
  }

  it "errors unless access is switchable" do
    course.update_attributes! is_access_switchable: false
    expect{
      result = subject.call(course: course)
      expect(result.errors).not_to be_empty
    }.to_not change{ Lms::Models::Context.count }
    expect(course.reload.lms_contexts).to be_present
  end

  it "deletes the last lms context" do
    first_context = course.lms_contexts.first

    new_launch = Lms::Launch.from_request(
      FactoryBot.create(:launch_request, app: Lms::WilloLabs.new),
      authenticator: authenticator
    ).validate!
    Lms::PairLaunchToCourse.call(launch_uuid: new_launch.persist!, course: course)

    expect(course.lms_contexts.count).to eq 2

    expect do
      result = subject.call(course: course)
      expect(result.errors).to be_empty
    end.to change{ Lms::Models::Context.count }.by -1

    expect(course.reload.lms_contexts.count).to eq 1
    expect(course.reload.lms_contexts.first).to eq first_context
  end
end
