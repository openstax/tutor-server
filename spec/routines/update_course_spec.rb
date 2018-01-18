require 'rails_helper'

RSpec.describe UpdateCourse do
  let(:course) { FactoryBot.create :course_profile_course }

  it 'updates the course name' do
    result = UpdateCourse.call(course.id, { name: 'Physics' })
    expect(result.errors).to be_empty
    expect(course.reload.name).to eq 'Physics'
  end

  it 'updates the course time_zone' do
    result = UpdateCourse.call(course.id, { time_zone: 'Eastern Time (US & Canada)' })
    expect(result.errors).to be_empty
    expect(course.reload.time_zone.name).to eq 'Eastern Time (US & Canada)'
  end

  it 'does not allow the time_zone to be set to invalid values' do
    result = UpdateCourse.call(course.id, { time_zone: 'invalid' })
    expect(result.errors.first.code).to eq :invalid_time_zone
    expect(course.reload.time_zone).to be_valid
  end
end
