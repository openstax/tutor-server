require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetTpPerformanceReport, type: :routine, speed: :slow do

  before(:all) do
    DatabaseCleaner.start

    VCR.use_cassette("Tasks_GetTpPerformanceReport/with_book", VCR_OPTS) do
      @ecosystem = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end
    @course = FactoryGirl.create :entity_course, :with_assistants
    CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)

    @teacher = FactoryGirl.create(:user)
    SetupPerformanceReportData[course: @course, teacher: @teacher, ecosystem: @ecosystem]
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  let(:expected_periods)    { 2 }
  let(:expected_students)   { 2 }

  let(:expected_tasks)      { 3 }
  let(:expected_task_types) { ['homework', 'reading', 'homework'] }

  it 'has the proper structure' do
    reports = described_class[course: @course]
    expect(reports.size).to eq expected_periods
    reports.each_with_index do |report, rindex|
      expect(report.data_headings.size).to eq expected_tasks
      data_heading_types = report.data_headings.map(&:type)
      expect(data_heading_types).to eq expected_task_types

      expect(report.students.size).to eq expected_students
      student_identifiers = report.students.map(&:student_identifier)
      expect(Set.new student_identifiers).to eq Set.new ["S#{2*rindex + 1}", "S#{2*rindex + 2}"]

      report.students.each do |student|
        expect(student.data.size).to eq expected_tasks
        data_types = student.data.map(&:type)
        expect(data_types).to eq expected_task_types
      end
    end
  end

  it 'does not blow up when a student was not assigned a particular task' do
    @course.students.first.role.taskings.first.task.destroy
    expect {
      described_class[course: @course]
    }.not_to raise_error
  end

  it 'does not blow up when a student has no first_name' do
    @course.students.first.role.profile.account.update_attribute(:first_name, nil)
    expect {
      described_class[course: @course]
    }.not_to raise_error
  end

  it 'does not blow up when a student has no last_name' do
    @course.students.first.role.profile.account.update_attribute(:last_name, nil)
    expect {
      described_class[course: @course]
    }.not_to raise_error
  end

end
