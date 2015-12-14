require 'rails_helper'

RSpec.describe Admin::CoursesCreate, type: :handler do
  subject(:course_profile) { CourseProfile::Models::Profile.last }

  it 'names the course' do
    described_class.handle(params: { course: { name: 'Hello course' } })
    expect(course_profile.name).to eq('Hello course')
  end

  it 'requires a name' do
    result = described_class.handle(params: { course: {} })
    error = result.errors.last

    expect(error.offending_inputs).to eq([:course, :name])
    expect(error.message).to eq("can't be blank")
  end

  it 'assigns the course to a school' do
    school = SchoolDistrict::CreateSchool.call(name: 'Hello school')

    described_class.handle(params: { course: { name: 'Hello course',
                                               school_district_school_id: school.id } })

    expect(course_profile.school_name).to eq('Hello school')
  end
end
