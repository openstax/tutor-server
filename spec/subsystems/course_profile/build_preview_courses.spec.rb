require 'rails_helper'

RSpec.describe CourseProfile::BuildPreviewCourses do
  let!(:offerings) {
    2.times.map { FactoryGirl.create :catalog_offering, is_tutor: true }
  }

  it 'queries for needed offerings' do
    needed = described_class.new.send(:offerings_that_need_previews, 10)
    expect(needed.map(&:id)).to eq offerings.map(&:id)
    expect(needed.map(&:course_preview_count)).to eq [0, 0]
  end

  it 'launches from schedule' do
    expect(CourseProfile::Models::Course).to(
      receive(:with_advisory_lock)
        .with('preview-builder', 0)
        .and_yield
    )
    expect(described_class).to receive(:call)
    described_class.run_scheduled_build
  end

  it 'builds specified number of preview courses for each offering' do
    described_class[desired_count: 2]
    offerings.each do |offering|
      expect(
        offering.courses(true).where(is_preview: true, preview_claimed_at: nil).count
      ).to be 2
    end
  end
end
