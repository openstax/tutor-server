# coding: utf-8
require 'rails_helper'

RSpec.describe CourseProfile::ClaimPreviewCourse do
  let(:offering) { FactoryGirl.create :catalog_offering }
  let(:term) { TermYear.visible_term_years.first }

  context 'with preview available' do
    let!(:course) {
      CreateCourse.call(
        name: 'Unclaimed',
        term: term.term,
        year: term.year,
        time_zone: 'Indiana (East)',
        is_preview: true,
        is_college: true,
        catalog_offering: offering,
        estimated_student_count: 42
      ).outputs.course
    }

    it 'finds the course and updates it’s attributes' do
      course.update_attributes!(created_at: 3.days.ago)
      claimed_course = CourseProfile::ClaimPreviewCourse[
        catalog_offering: offering, name: 'My New Preview Course'
      ]
      expect(claimed_course.id).to eq course.id
      expect(claimed_course.name).to eq 'My New Preview Course'
      expect(claimed_course.preview_claimed_at).to be_within(1.minute).of(Time.now)
      claimed_course
    end
  end


  context 'when no previews are pre-built' do
    it 'errors with api code and sends email' do
      result = CourseProfile::ClaimPreviewCourse.call(
        catalog_offering: offering, name: 'My New Preview Course'
      )
      expect(result.errors.first.code).to eq :no_preview_courses_available
      expect(ActionMailer::Base.deliveries.last.subject).to match('Failed to find preview course')
    end
  end

end
