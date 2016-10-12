require 'rails_helper'

RSpec.describe Admin::CoursesCreate, type: :handler do
  let(:handler_result)     { described_class.handle(params: @params) }
  subject(:course_profile) { handler_result.outputs["[:create_course, :profile]"] }

  it 'names the course' do
    @params = {
      course: {
        name: 'Hello course' ,
        starts_at: Time.current,
        ends_at: Time.current + 1.week,
        is_concept_coach: false,
        is_college: true
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
        starts_at: Time.current,
        ends_at: Time.current + 1.week,
        is_concept_coach: false,
        is_college: true,
        school_district_school_id: school.id
      }
    }

    expect(course_profile.school_name).to eq('Hello school')
  end
end
