require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::ExportPerformanceReport, type: :routine, speed: :slow do

  before(:all) do
    VCR.use_cassette("Tasks_ExportPerformanceReport/with_book", VCR_OPTS) do
      @ecosystem = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end
    @course = FactoryGirl.create :entity_course, :with_assistants
    CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)

    @teacher = FactoryGirl.create(:user)
    SetupPerformanceReportData[course: @course, teacher: @teacher, ecosystem: @ecosystem]
    @role = GetUserCourseRoles[course: @course, user: @teacher].first
  end

  after(:each) do
    File.delete(@output_filename) if !@output_filename.nil? && File.exist?(@output_filename)
  end

  it 'does not blow up' do
    expect {
      @output_filename = described_class[role: @role, course: @course]
    }.not_to raise_error
  end

  it 'does not blow up when a student was not assigned a particular task' do
    @course.students.first.role.taskings.first.task.destroy
    expect {
      @output_filename = described_class[role: @role, course: @course]
    }.not_to raise_error
  end

  it 'does not blow up if the course name has forbidden characters' do
    @course.profile.update_attribute(:name, "My/\\C00l\r\n\tC0ur$3 :-)")
    expect {
      @output_filename = described_class[role: @role, course: @course]
    }.not_to raise_error
  end

end
