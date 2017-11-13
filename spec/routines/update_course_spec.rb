require 'rails_helper'

RSpec.describe UpdateCourse do
  let(:course) { FactoryBot.create :course_profile_course }

  it 'updates the course name' do
    UpdateCourse.call(course.id, { name: 'Physics' })
    expect(course.reload.name).to eq 'Physics'
  end
end
