require 'rails_helper'

RSpec.describe CourseProfile::BuildPreviewCourses do
  let!(:offerings) { 2.times.map { FactoryGirl.create :catalog_offering, is_tutor: true } }

  it 'queries for needed offerings' do
    needed = described_class.new.send(:offering_that_needs_previews, 10)
    expect(needed.id).to be_in offerings.map(&:id)
    expect(needed.course_preview_count).to eq 0
  end

  it 'launches from schedule' do
    expect { described_class.call }.not_to raise_error
  end

  it 'builds specified number of preview courses for each offering' do
    described_class[desired_count: 2]
    offerings.each do |offering|
      expect(offering.courses(true).where(is_preview: true, preview_claimed_at: nil).count).to eq 2
    end
  end
end
