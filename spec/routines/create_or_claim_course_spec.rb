require 'rails_helper'

RSpec.describe CreateOrClaimCourse, type: :routine do
  let(:mock_course) { OpenStruct.new('is_preview?': is_preview, id: 42 ) }

  context 'a preview course' do

    let(:is_preview) { true }

    it "claims an existing preview" do
      expect_any_instance_of(CourseProfile::ClaimPreviewCourse)
        .to receive(:call).with(catalog_offering: 123, name:'TEST') {
        Lev::Routine::Result.new(Lev::Outputs.new({course: mock_course}), Lev::Errors.new)
      }

      expect_any_instance_of(AddUserAsCourseTeacher)
        .to receive(:call).with(course: mock_course, user: 'TEACH') { |routine, *args| routine.send(:result)}

      expect(TrackTutorOnboardingEvent).to receive(:perform_later)
                                             .with(event: 'created_preview_course', user: 'TEACH',
                                                   data: { course_id: 42 })

      described_class.call(is_preview: true, teacher: 'TEACH', name:'TEST', catalog_offering: 123)
    end
  end

  context 'a regular course' do
    let(:is_preview) { false }

    it "creates a new course" do

      expect_any_instance_of(CreateCourse)
        .to receive(:call) {
        Lev::Routine::Result.new(Lev::Outputs.new({course: mock_course}), Lev::Errors.new)
      }

      expect_any_instance_of(AddUserAsCourseTeacher)
        .to receive(:call) { |routine, *args| routine.send(:result)}

      expect(TrackTutorOnboardingEvent).to receive(:perform_later)
                                             .with(event: 'created_real_course', user: 'TEACH',
                                                   data: { course_id: 42 })

      described_class.call(is_preview: false, teacher: 'TEACH')
    end
  end

end
