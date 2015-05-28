require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::ExportPerformanceBook, speed: :slow, vcr: VCR_OPTS do
  let(:course) { CreateCourse[name: 'Physics'] }
  let(:teacher) { FactoryGirl.create :user_profile }

  before(:each) do
    OpenStax::Exercises::V1.use_real_client

    book = FetchAndImportBook[id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58']
    SetupPerformanceBookData[course: course, teacher: teacher, book: book]
  end

  it 'does not blow up' do
    role = GetUserCourseRoles[course: course, user: teacher.entity_user].first
    expect {
      output_filename = described_class[role: role, course: course]
      File.delete(output_filename) if File.exist? output_filename
    }.not_to raise_error
  end
end
