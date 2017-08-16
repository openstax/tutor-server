require 'rails_helper'

RSpec.describe CourseProfile::BuildPreviewCourses, type: :routine, truncation: true do
  let!(:offerings) { 2.times.map { FactoryGirl.create :catalog_offering, is_tutor: true } }

  it 'queries for needed offerings' do
    needed = described_class.new.send(:offering_that_needs_previews, 2)
    expect(needed.id).to be_in offerings.map(&:id)
    expect(needed.course_preview_count).to eq 0
  end

  it 'launches from schedule' do
    begin
      @previous_prebuilt_preview_course_count = Settings::Db.store.prebuilt_preview_course_count
      Settings::Db.store.prebuilt_preview_course_count = 2
      expect { described_class.call }.not_to raise_error
    ensure
      Settings::Db.store.prebuilt_preview_course_count = @previous_prebuilt_preview_course_count
    end
  end

  it 'builds specified number of preview courses for each offering' do
    expect(PopulatePreviewCourseContent).to(
      receive(:perform_later).exactly(offerings.size * 2).times
    )

    described_class[desired_count: 2]

    offerings.each do |offering|
      expect(offering.courses.where(is_preview: true, preview_claimed_at: nil).count).to eq 2
    end
  end
end
