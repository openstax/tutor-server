require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetCcPerformanceReport, type: :routine, speed: :slow do

  before(:all) do
    DatabaseCleaner.start

    VCR.use_cassette("Tasks_GetCcPerformanceReport/with_book", VCR_OPTS) do
      @ecosystem = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end
    @course = CreateCourse[name: 'Physics']
    CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)

    @teacher = FactoryGirl.create(:user)
    SetupPerformanceReportData[course: @course, teacher: @teacher, ecosystem: @ecosystem]

    # Transform the course into a CC course
    @course.profile.update_attribute(:is_concept_coach, true)
    @course.students.each do |student|
      Tasks::Models::Task.joins(entity_task: :taskings)
                         .where(entity_task: {taskings: {entity_role_id: student.entity_role_id}},
                                task_type: 'homework').to_a.each_with_index do |task, index|
        task.task_type = 'concept_coach'
        task.task_plan = nil
        task.save!

        Tasks::Models::ConceptCoachTask.create!(
          content_page_id: @ecosystem.books.first.chapters.third.pages[index].id,
          role: task.taskings.first.role,
          task: task.entity_task
        )
      end
    end
    Tasks::Models::TaskPlan.destroy_all
  end

  after(:each) do
    File.delete(@output_filename) if !@output_filename.nil? && File.exist?(@output_filename)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  let(:expected_periods)   { 2 }
  let(:expected_students)  { 2 }

  let(:expected_tasks)     { [2, 1] }
  let(:expected_task_type) { 'concept_coach' }

  it 'has the proper structure' do
    reports = described_class[course: @course]
    expect(reports.size).to eq expected_periods
    valid_page_uuids = @ecosystem.books.first.pages.map(&:uuid)
    reports.each_with_index do |report, rindex|
      expect(report.data_headings.size).to eq expected_tasks[rindex]
      report.data_headings.each do |data_heading|
        expect(data_heading.title).to match(/\A[\d+]\.[\d+] /)
        expect(valid_page_uuids).to include(data_heading.cnx_page_id)
        expect(data_heading.type).to eq expected_task_type
      end

      expect(report.students.size).to eq expected_students
      student_identifiers = report.students.map(&:student_identifier)
      expect(Set.new student_identifiers).to eq Set.new ["S#{2*rindex + 1}", "S#{2*rindex + 2}"]

      report.students.each do |student|
        expect(student.data.size).to be <= expected_tasks[rindex]
        student.data.map(&:type).each do |data_type|
          expect(data_type).to eq expected_task_type
        end
      end
    end
  end

  it 'does not blow up when a student did not work a particular task' do
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
