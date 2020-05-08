require 'rails_helper'

RSpec.describe UpdateCourse do
  let(:course) { FactoryBot.create :course_profile_course }

  it 'updates the course name' do
    result = UpdateCourse.call(course.id, { name: 'Physics' })
    expect(result.errors).to be_empty
    expect(course.reload.name).to eq 'Physics'
  end

  it 'updates the course timezone' do
    result = UpdateCourse.call(course.id, { timezone: 'US/Eastern' })
    expect(result.errors).to be_empty
    expect(course.reload.timezone).to eq 'US/Eastern'
  end

  it 'does not allow the timezone to be set to invalid values' do
    result = UpdateCourse.call(course.id, { timezone: 'invalid' })
    expect(result.errors.first.code).to eq :inclusion
    expect(course.reload).to be_valid
  end
end
