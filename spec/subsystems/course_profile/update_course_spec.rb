require 'rails_helper'

RSpec.describe CourseProfile::UpdateCourse do
  let(:course) { FactoryGirl.create :course_profile_course }

  it 'updates the course name' do
    described_class.call(course.id, { name: 'Physics' })
    expect(course.reload.name).to eq 'Physics'
  end

  it 'updates the is_college flag' do
    expect(course.is_college).to eq true
    described_class.call(course.id, { is_college: false })
    expect(course.reload.is_college).to eq false
  end
end
