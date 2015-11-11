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
    Tasks::Models::Task.where(task_type: 'homework').to_a.each do |task|
      task.task_type = 'concept_coach'
      task.task_plan = nil
      task.save!

      Tasks::Models::ConceptCoachTask.create!(
        task: task.entity_task, page: task.tasked_exercises.first.exercise.page
      )
    end
    Tasks::Models::TaskPlan.destroy_all
  end

  after(:each) do
    File.delete(@output_filename) if !@output_filename.nil? && File.exist?(@output_filename)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  let(:expected_periods)    { 2 }
  let(:expected_students)   { 2 }

  let(:expected_tasks)      { [2, 1] }
  let(:expected_task_type) { 'concept_coach' }

  it 'has the proper structure' do
    reports = described_class[course: @course]
    expect(reports.size).to eq expected_periods
    reports.each_with_index do |report, rindex|
      expect(report.data_headings.size).to eq expected_tasks[rindex]
      report.data_headings.map(&:type).each do |data_heading_type|
        expect(data_heading_type).to eq expected_task_type
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

end
