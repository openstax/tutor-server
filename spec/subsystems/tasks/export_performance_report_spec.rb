require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::ExportPerformanceReport, speed: :slow, vcr: VCR_OPTS do
  let(:course) { CreateCourse[name: 'Physics'] }
  let(:teacher) { FactoryGirl.create :user_profile }

  before(:each) do
    book = FetchAndImportBookAndCreateEcosystem[id: '93e2b09d-261c-4007-a987-0b3062fe154b']
    SetupPerformanceReportData[course: course, teacher: teacher, book: book]
  end

  it 'does not blow up' do
    role = GetUserCourseRoles[course: course, user: teacher.entity_user].first
    expect {
      output_filename = described_class[role: role, course: course]
      File.delete(output_filename) if File.exist? output_filename
    }.not_to raise_error
  end
end
