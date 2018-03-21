require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetCcPerformanceReport, type: :routine do

  before(:all) do
    VCR.use_cassette("Tasks_GetCcPerformanceReport/with_book", VCR_OPTS) do
      @ecosystem = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end
    @course = FactoryBot.create :course_profile_course, :with_assistants, is_concept_coach: true
    CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)

    @teacher = FactoryBot.create(:user)
    SetupPerformanceReportData[course: @course, teacher: @teacher, ecosystem: @ecosystem]

    # Transform the course into a CC course
    @course.students.each do |student|
      Tasks::Models::Task.joins(:taskings)
                         .where(taskings: {entity_role_id: student.entity_role_id},
                                task_type: 'homework').to_a.each_with_index do |task, index|
        task.task_type = 'concept_coach'
        task.task_plan = nil
        task.save!

        Tasks::Models::ConceptCoachTask.create!(
          content_page_id: @ecosystem.books.first.chapters.third.pages[index].id,
          role: task.taskings.first.role,
          task: task
        )
      end
    end
    Tasks::Models::TaskPlan.destroy_all
  end

  after(:each) do
    File.delete(@output_filename) if !@output_filename.nil? && File.exist?(@output_filename)
  end

  let(:teacher_role)                  { @teacher.to_model.roles.first }
  let(:student_role)                  { @course.students.first.role }

  let(:expected_periods)              { 2 }
  let(:expected_students)             { 2 }

  let(:expected_tasks)                { [2, 1] }
  let(:expected_task_type)            { 'concept_coach' }

  let(:first_period)                  { @course.periods.order(:created_at).first }
  let(:first_student_of_first_period) do
    first_period.students.preload(role: {role_user: :profile}).sort_by do |student|
      sort_name = "#{student.role.last_name} #{student.role.first_name}"
      (sort_name.blank? ? student.role.name : sort_name).downcase
    end.first
  end

  let(:reports)                       { described_class[course: @course, role: teacher_role] }
  let(:first_period_report)           do
    reports.find { |report| report[:period] == first_period }
  end

  it 'has the proper structure' do
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
        student.data.compact.map(&:type).each do |data_type|
          expect(data_type).to eq expected_task_type
        end
      end
    end
  end

  it 'raises SecurityTransgression for a student role' do
    expect { described_class[course: @course, role: student_role] }.to(
      raise_error(SecurityTransgression)
    )
  end

  context 'for incomplete CC tasks' do
    it 'includes them in averages' do
      incomplete_cc = first_period_report.students.second.data.first
      expect(incomplete_cc.is_included_in_averages).to eq true
      # First task would have an average of 1.0 if incomplete not included
      expect(first_period_report.data_headings.first.average_score).to be_within(1e-6).of(2/3.0)
    end
  end

  it 'returns nil when a student did not work a particular task' do
    first_student_of_first_period.role.taskings.first.task.really_destroy!
    expect(first_period_report[:students].first[:data]).to include nil
  end

  it 'returns several nils when a student did not work any tasks' do
    first_student_of_first_period.role.taskings.each{ |tasking| tasking.task.really_destroy! }
    expect(first_period_report[:students].first[:data]).to eq [nil]*expected_tasks.first
  end

  it 'works when a student has no first_name' do
    first_student_of_first_period.role.profile.account.update_attribute(:first_name, nil)
    expect { reports }.not_to raise_error
  end

  it 'works when a student has no last_name' do
    first_student_of_first_period.role.profile.account.update_attribute(:last_name, nil)
    expect { reports }.not_to raise_error
  end

  it 'excludes dropped students from the performance report' do
    CourseMembership::InactivateStudent.call(student: first_student_of_first_period)

    expect(reports).not_to include(
      a_hash_including(
        students: a_collection_including(
          a_hash_including(name: first_student_of_first_period.name)
        )
      )
    )
  end
end
