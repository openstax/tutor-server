require 'rails_helper'

RSpec.describe CourseProfile::BuildPreviewCourses, type: :routine do
  before(:all) do
    @offerings = 2.times.map { FactoryBot.create :catalog_offering, is_tutor: true }

    @offerings.each do |offering|
      # Not counted because no ecosystem
      no_eco_course = FactoryBot.create(
        :course_profile_course, offering: offering, is_preview: true
      )
      no_eco_course.course_ecosystems.delete_all :delete_all

      # Not counted because initial ecosystem is different
      old_eco_course = FactoryBot.create(
        :course_profile_course, offering: offering, is_preview: true
      )
      FactoryBot.create :course_content_course_ecosystem,
                        course: old_eco_course, created_at: Time.current - 1.hour
    end
  end

  it 'queries for needed offerings' do
    needed = described_class.new.send(:offering_that_needs_previews, 2)
    expect(needed.id).to be_in @offerings.map(&:id)
    expect(needed.preview_course_count).to eq 0
  end

  it 'launches from schedule' do
    begin
      @previous_prebuilt_preview_course_count = Settings::Db.prebuilt_preview_course_count
      Settings::Db.prebuilt_preview_course_count = 2
      expect { described_class.call }.not_to raise_error
    ensure
      Settings::Db.prebuilt_preview_course_count = @previous_prebuilt_preview_course_count
    end
  end

  it 'builds specified number of preview courses for each offering' do
    expect(PopulatePreviewCourseContent).to(
      receive(:perform_later).exactly(@offerings.size * 2).times
    )

    expect { described_class[desired_count: 2] }.to(
      change { @offerings.map { |offering| offering.courses.count }.sum }.by(@offerings.size * 2)
    )

    expect { described_class[desired_count: 2] }.not_to(
      change { @offerings.map { |offering| offering.courses.count }.sum }
    )
  end

  it 'counts preview courses that initially had the most recent ecosystem' do
    @offerings.each do |offering|
      FactoryBot.create :course_profile_course, offering: offering, is_preview: true
    end

    expect(PopulatePreviewCourseContent).to receive(:perform_later).exactly(@offerings.size).times

    described_class[desired_count: 2]
  end
end
