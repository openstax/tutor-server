require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::ExportPerformanceReport, type: :routine, speed: :slow do

  before(:all) do
    DatabaseCleaner.start

    VCR.use_cassette("Tasks_ExportPerformanceReport/with_book", VCR_OPTS) do
      @ecosystem = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end
    @course = CreateCourse.call(name: 'Physics')
    CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)

    @teacher = FactoryGirl.create(:user)
    SetupPerformanceReportData.call(course: @course, teacher: @teacher, ecosystem: @ecosystem)
    @role = GetUserCourseRoles.call(course: @course, user: @teacher).first
  end

  after(:each) do
    File.delete(@output_filename) if !@output_filename.nil? && File.exist?(@output_filename)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  it 'does not blow up' do
    expect {
      @output_filename = described_class.call(role: @role, course: @course)
    }.not_to raise_error
  end

  it 'does not blow up when a student was not assigned a particular task' do
    @course.students.first.role.taskings.first.task.destroy
    expect {
      @output_filename = described_class.call(role: @role, course: @course)
    }.not_to raise_error
  end

end
