require 'rails_helper'

RSpec.describe CourseProfile::UpdateProfile do
  let(:course) { FactoryGirl.create :entity_course }

  it 'updates the course name' do
    CourseProfile::UpdateProfile.call(course.id, { name: 'Physics' })
    expect(course.reload.name).to eq 'Physics'
  end

  it 'updates the is_college flag' do
    expect(course.profile.is_college).to eq true
    CourseProfile::UpdateProfile.call(course.id, { is_college: false })
    expect(course.reload.profile.is_college).to eq false
  end
end
