require 'rails_helper'

RSpec.describe CreateCourse, type: :routine do
  let(:term)             { CourseProfile::Models::Course.terms.keys.sample }
  let(:year)             { Time.current.year }
  let(:is_college)       { true }
  let(:catalog_offering) { FactoryGirl.create :catalog_offering }

  it "creates a new course" do
    result = described_class.call(
      name: 'Unnamed',
      term: term,
      year: year,
      is_college: is_college,
      catalog_offering: catalog_offering
    )
    expect(result.errors).to be_empty

    course = result.outputs.course

    expect(course).to be_a CourseProfile::Models::Course
    expect(course.course_assistants.count).to eq 4
  end

  it 'adds a unique registration code for the teacher' do
    allow(SecureRandom).to receive(:hex) { 'abc123' }

    course = described_class.call(
      name: 'Reg Code Course',
      term: term,
      year: year,
      is_college: is_college,
      catalog_offering: catalog_offering
    ).outputs.course

    expect(course.teach_token).to eq('abc123')
  end
end
