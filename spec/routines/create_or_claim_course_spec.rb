require 'rails_helper'

RSpec.describe CreateOrClaimCourse, type: :routine do
  let(:user)        { OpenStruct.new(is_test: is_test, school_type: 'college', is_kip: true) }
  let(:mock_course) { OpenStruct.new(id: 42, is_preview?: is_preview, is_test?: is_test) }

  context 'a preview course' do
    let(:is_preview) { true }
    let(:is_test)    { false }

    it 'claims an existing preview' do
      expect_any_instance_of(CourseProfile::ClaimPreviewCourse)
        .to receive(:call).with(catalog_offering: 123, name: 'TEST', is_college: true) do
        Lev::Routine::Result.new(Lev::Outputs.new(course: mock_course), Lev::Errors.new)
      end

      expect_any_instance_of(AddUserAsCourseTeacher)
        .to receive(:call).with(course: mock_course, user: user) do |routine, *args|
          routine.send(:result)
      end

      expect(TrackTutorOnboardingEvent).to receive(:perform_later).with(
        event: 'created_preview_course', user: user, data: { course_id: 42 }
      )

      described_class.call(is_preview: true, teacher: user, name: 'TEST', catalog_offering: 123)
    end
  end

  context 'a regular course' do
    let(:is_preview) { false }
    let(:is_test)    { true }

    it 'creates a new course, setting is_college and does_cost' do
      expect_any_instance_of(CreateCourse).to receive(:call) do |**options|
        expect(options[:is_college]).to eq true
        expect(options[:does_cost]).to eq false

        Lev::Routine::Result.new(Lev::Outputs.new(course: mock_course), Lev::Errors.new)
      end

      expect_any_instance_of(AddUserAsCourseTeacher)
        .to receive(:call) { |routine, *args| routine.send(:result) }

      expect(TrackTutorOnboardingEvent).to receive(:perform_later).with(
        event: 'created_real_course', user: user, data: { course_id: 42 }
      )

      described_class.call(is_preview: false, teacher: user)
    end
  end
end
