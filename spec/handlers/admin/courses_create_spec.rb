require 'rails_helper'

RSpec.describe Admin::CoursesCreate, type: :handler do
  let(:catalog_offering)   { FactoryGirl.create :catalog_offering }
  let(:handler_result)     { described_class.handle(params: @params) }
  subject(:course_profile) { handler_result.outputs["[:create_course, :profile]"] }

  it 'names the course' do
    @params = {
      course: {
        name: 'Hello course' ,
        term: CourseProfile::Models::Profile.terms.keys.sample,
        year: Time.current.year,
        is_concept_coach: false,
        is_college: true,
        catalog_offering_id: catalog_offering.id
      }
    }

    expect(course_profile.name).to eq('Hello course')
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
        term: CourseProfile::Models::Profile.terms.keys.sample,
        year: Time.current.year,
        is_concept_coach: false,
        is_college: true,
        catalog_offering_id: catalog_offering.id,
        school_district_school_id: school.id
      }
    }

    expect(course_profile.school_name).to eq('Hello school')
  end

  it 'can directly assign the course start and end dates' do
    starts_at = Time.current
    ends_at = starts_at + 1.hour

    @params = {
      course: {
        name: 'Hello course' ,
        term: CourseProfile::Models::Profile.terms.keys.sample,
        year: Time.current.year,
        starts_at: starts_at,
        ends_at: ends_at,
        is_concept_coach: false,
        is_college: true,
        catalog_offering_id: catalog_offering.id
      }
    }

    expect(course_profile.starts_at).to eq starts_at
    expect(course_profile.ends_at  ).to eq ends_at
  end
end
