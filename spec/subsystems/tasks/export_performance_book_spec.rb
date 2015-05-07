require 'rails_helper'

RSpec.describe Tasks::ExportPerformanceBook do
  let(:course) { CreateCourse[name: 'Physics'] }
  let(:teacher) { FactoryGirl.create :user_profile }

  before do
    SetupPerformanceBookData[course: course, teacher: teacher]
  end

  it 'does not blow up' do
    role = GetUserCourseRoles[course: course, user: teacher.entity_user].first
    described_class[role: role, course: course]
    expect(1).to eq(1)
  end
end
