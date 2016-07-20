require 'rails_helper'

RSpec.describe CourseProfile::UpdateProfile do
  let(:course) { CreateCourse[name: 'A course'] }

  it 'updates the course name' do
    CourseProfile::UpdateProfile.call(course.id, { name: 'Physics' })
    expect(course.reload.name).to eq 'Physics'
  end

  it 'updates the is_college flag' do
    expect(course.reload.profile.is_college).to eq false
    CourseProfile::UpdateProfile.call(course.id, { is_college: true })
    expect(course.reload.profile.is_college).to eq true
  end
end
