require 'rails_helper'

RSpec.describe Admin::CoursesCreate, type: :handler do
  let(:catalog_offering) { FactoryBot.create :catalog_offering }
  let(:handler_result)   { described_class.handle(params: @params) }
  subject(:course)       { handler_result.outputs["[:create_course, :course]"] }

  it 'names the course' do
    @params = {
      course: {
        name: 'Hello course' ,
        term: CourseProfile::Models::Course.terms.keys.sample,
        year: Time.current.year,
        is_test: false,
        is_preview: false,
        is_college: true,
        num_sections: 0,
        catalog_offering_id: catalog_offering.id
      }
    }

    expect(course.name).to eq('Hello course')
  end

  it 'requires a name' do
    @params = { course: {} }

    expect(handler_result.errors.map(&:offending_inputs)).to include([:course, :name])
    expect(handler_result.errors.full_messages          ).to include("Name can't be blank")
  end

  it 'assigns the course to a school' do
    school = SchoolDistrict::CreateSchool[name: 'Hello school']

    @params = {
      course: {
        name: 'Hello course' ,
        term: CourseProfile::Models::Course.terms.keys.sample,
        year: Time.current.year,
        is_test: false,
        is_preview: false,
        is_college: true,
        num_sections: 0,
        catalog_offering_id: catalog_offering.id,
        school_district_school_id: school.id
      }
    }

    expect(course.school_name).to eq('Hello school')
  end

  it 'can directly assign the course start and end dates' do
    starts_at = Time.current
    ends_at = starts_at + 1.hour

    @params = {
      course: {
        name: 'Hello course' ,
        term: CourseProfile::Models::Course.terms.keys.sample,
        year: Time.current.year,
        starts_at: starts_at,
        ends_at: ends_at,
        is_test: false,
        is_preview: false,
        is_college: true,
        num_sections: 0,
        catalog_offering_id: catalog_offering.id
      }
    }

    expect(course.starts_at).to be_within(1e-6).of(starts_at)
    expect(course.ends_at  ).to be_within(1e-6).of(ends_at)
  end

  it 'creates the specified number of sections for the course' do
    @params = {
      course: {
        name: 'Hello course' ,
        term: CourseProfile::Models::Course.terms.keys.sample,
        year: Time.current.year,
        is_test: false,
        is_preview: false,
        is_college: true,
        num_sections: 2,
        catalog_offering_id: catalog_offering.id
      }
    }

    expect(course.num_sections).to eq 2
  end
end
