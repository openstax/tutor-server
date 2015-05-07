require 'rails_helper'

RSpec.describe Tasks::ExportPerformanceBook do
  let(:course) { Entity::Course.create! }
  let(:teacher) { FactoryGirl.create :user_profile }

  before do
    SetupPerformanceBookData[course: course, teacher: teacher]
  end

  it 'does not blow up' do
    role = GetUserCourseRoles[course: course, user: teacher.entity_user].first
    book = Tasks::GetPerformanceBook[course: course, role: role]
    binding.pry
  end
end
