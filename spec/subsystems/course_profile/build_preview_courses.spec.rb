require 'rails_helper'

RSpec.describe CourseProfile::ClaimPreviewCourse do
  let!(:offerings) {
    2.times.map { FactoryGirl.create :catalog_offering, is_tutor: true }
  }

  it 'queries for needed offerings' do
    needed = CourseProfile::BuildPreviewCourses.offerings_that_need_previews
    expect(needed.map(&:id)).to eq offerings.map(&:id)
    expect(needed.map(&:course_preview_count)).to eq [0, 0]
  end

  it 'launches in background' do
    expect(Jobba).to receive(:where)
                       .with(job_name: 'CourseProfile::BuildPreviewCourses')
                       .and_return(OpenStruct.new(:none? => true))
    expect(CourseProfile::BuildPreviewCourses).to receive(:perform_later)
    CourseProfile::BuildPreviewCourses.start_in_background
  end

  it 'builds specified number of preview courses for each offering' do
    CourseProfile::BuildPreviewCourses[desired_count: 2]
    offerings.each do |offering|
      expect(
        offering.courses(true).where(is_preview: true, preview_claimed_at: nil).count
      ).to be 2
    end
  end


end
