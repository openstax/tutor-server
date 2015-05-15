require 'rails_helper'

RSpec.describe Tasks::ExportPerformanceBook do
  let(:course) { CreateCourse[name: 'Physics'] }
  let(:teacher) { FactoryGirl.create :user_profile }

  before do
    book = FetchAndImportBook[id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58']
    SetupPerformanceBookData[course: course, teacher: teacher, book: book]
  end

  it 'does not blow up' do
    role = GetUserCourseRoles[course: course, user: teacher.entity_user].first
    expect {
      described_class[role: role, course: course]
    }.not_to raise_error
  end
end
