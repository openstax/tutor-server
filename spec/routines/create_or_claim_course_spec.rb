require 'rails_helper'

RSpec.describe CreateOrClaimCourse, type: :routine do


  it "claims a preview" do
    expect_any_instance_of(CourseProfile::ClaimPreviewCourse)
      .to receive(:call)
            .with(catalog_offering: 123, name:'TEST') { |routine, *args| routine.send(:result) }

    expect_any_instance_of(AddUserAsCourseTeacher)
      .to receive(:call)
            .with(course: nil, user: 'TEACH') { |routine, *args| routine.send(:result)}

    described_class.call(is_preview: true, teacher: 'TEACH', name:'TEST', catalog_offering: 123)
  end

  it "creates a new regular course and adds teacher when preview is false" do
    expect_any_instance_of(CreateCourse)
      .to receive(:call) { |routine, *args| routine.send(:result) }
    expect_any_instance_of(AddUserAsCourseTeacher)
      .to receive(:call) { |routine, *args| routine.send(:result)}

    described_class.call(is_preview: false)
  end

end
