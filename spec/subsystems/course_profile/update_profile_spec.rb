require 'rails_helper'

RSpec.describe CourseProfile::UpdateProfile do
  let!(:course) { CreateCourse.call(name: 'A course').course }

  it 'updates the course name' do
    CourseProfile::UpdateProfile.call(course.id, { name: 'Physics' })
    expect(course.reload.name).to eq 'Physics'
  end
end
