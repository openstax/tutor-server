require 'rails_helper'

RSpec.describe AddUserAsCourseTeacher, type: :routine do
  let(:user) { FactoryGirl.create :user }

  context "when the given user is not a teacher in the given course" do
    it "returns the user's new teacher role" do
      expect(TrackTutorOnboardingEvent)
        .to receive(:perform_later).with(event: 'created_real_course', user: user)

      course = FactoryGirl.create :course_profile_course

      result = AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to be_empty
      expect(result.outputs.role).to_not be_nil
    end
  end
  context "when the given user is a teacher in the given course" do
    it "has errors" do
      expect(TrackTutorOnboardingEvent).to receive(:perform_later).once

      course = FactoryGirl.create :course_profile_course
      result = AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to be_empty
      expect(result.outputs.role).to_not be_nil

      result = AddUserAsCourseTeacher.call(user: user, course: course)
      expect(result.errors).to_not be_empty
    end
  end

  context "tracking onboarding events" do
    let(:mock_course) { OpenStruct.new('is_preview?': is_preview) }
    before(:each) {
      expect_any_instance_of(Role::CreateUserRole)
        .to receive(:call) { |routine, *args| routine.send(:result)}
      expect_any_instance_of(CourseMembership::AddTeacher)
        .to receive(:call) { |routine, *args| routine.send(:result)}
    }
    context "a preview course" do
      let(:is_preview) { true }

      it 'tracks a preview created' do
        expect(TrackTutorOnboardingEvent).to receive(:perform_later)
                                               .with(event: 'created_preview_course', user: user)
        described_class.call(user: user, course: mock_course)
      end
    end

    context "a regular course" do
      let(:is_preview) { false }

      it 'tracks a preview created' do
        expect(TrackTutorOnboardingEvent).to receive(:perform_later)
                                               .with(event: 'created_real_course', user: user)
        described_class.call(user: user, course: mock_course)
      end
    end
  end
end
