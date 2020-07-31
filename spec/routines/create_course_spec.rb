require 'rails_helper'

RSpec.describe CreateCourse, type: :routine do
  let(:term)             { CourseProfile::Models::Course.terms.keys.sample }
  let(:year)             { Time.current.year }
  let(:is_college)       { [true, false].sample }
  let(:catalog_offering) { FactoryBot.create :catalog_offering }

  it "creates a new regular course" do
    result = described_class.call(
      name: 'Unnamed',
      term: term,
      year: year,
      timezone: 'US/East-Indiana',
      is_preview: false,
      is_college: is_college,
      is_test: true,
      catalog_offering: catalog_offering,
      estimated_student_count: 42
    )
    expect(result.errors).to be_empty

    course = result.outputs.course
    expect(course.timezone).to eq 'US/East-Indiana'
    expect(course).to be_a CourseProfile::Models::Course
    expect(course.course_assistants.count).to eq 4
    expect(course.is_preview).to eq false
    expect(course.is_college).to eq is_college
    expect(course.term).to eq term
    expect(course.year).to eq year
    expect(course.estimated_student_count).to eq 42
  end

  it "creates a new preview course" do
    result = described_class.call(
      name: 'Unnamed',
      timezone: 'US/East-Indiana',
      is_preview: true,
      is_college: is_college,
      is_test: false,
      catalog_offering: catalog_offering
    )
    expect(result.errors).to be_empty

    course = result.outputs.course

    expect(course).to be_a CourseProfile::Models::Course
    expect(course.course_assistants.count).to eq 4
    expect(course.is_preview).to eq true
    expect(course.is_college).to eq is_college
    expect(course.term).to eq 'preview'
    expect(course.year).to eq year
  end

  it "requires the term and year attributes for non-preview courses" do
    result = described_class.call(
      name: 'Unnamed',
      timezone: 'US/East-Indiana',
      is_preview: false,
      is_college: is_college,
      is_test: true,
      catalog_offering: catalog_offering,
      estimated_student_count: 42
    )
    expect(result.errors.first.code).to eq :term_year_blank
  end

  it 'adds a unique registration code for the teacher' do
    allow(SecureRandom).to receive(:hex) { 'abc123' }

    course = described_class.call(
      name: 'Reg Code Course',
      term: term,
      year: year,
      timezone: 'US/East-Indiana',
      is_preview: false,
      is_college: is_college,
      is_test: true,
      catalog_offering: catalog_offering,
      estimated_student_count: 42
    ).outputs.course

    expect(course.teach_token).to eq('abc123')
    expect(course.is_preview).to eq false
    expect(course.is_college).to eq is_college
    expect(course.term).to eq term
    expect(course.year).to eq year
  end
end
