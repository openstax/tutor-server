require 'rails_helper'

RSpec.describe CourseProfile::MarkCourseEnrolled, type: :routine do
  let(:course) { FactoryBot.create :course_profile_course }

  it 'updates the is_access_switchable flag' do
    expect(course.is_access_switchable).to eq true
    described_class.call(course: course)
    expect(course.reload.is_access_switchable).to eq false
  end
end
