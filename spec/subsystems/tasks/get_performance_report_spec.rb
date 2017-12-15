require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetPerformanceReport, type: :routine, speed: :slow do

  before(:all) do
    VCR.use_cassette("Tasks_GetPerformanceReport/with_book", VCR_OPTS) do
      @ecosystem = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end
    @course = FactoryBot.create :course_profile_course, :with_assistants
    CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)

    @teacher = FactoryBot.create(:user)
    @student_1 = FactoryBot.create(:user)
    @student_2 = FactoryBot.create(:user)
    @student_3 = FactoryBot.create(:user)
    @student_4 = FactoryBot.create(:user)
    SetupPerformanceReportData[
      course: @course,
      teacher: @teacher,
      students: [@student_1, @student_2, @student_3, @student_4],
      ecosystem: @ecosystem
    ]
  end

  let(:expected_periods)              { 2 }
  let(:expected_students)             { 2 }

  let(:expected_tasks)                { 3 }
  let(:expected_task_types)           { ['homework', 'reading', 'homework'] }

  let(:first_period)                  { @course.periods.order(:created_at).first }
  let(:second_period)                 { @course.periods.order(:created_at).second }
  let(:first_student_of_first_period) do
    first_period.latest_enrollments.preload(student: {role: {role_user: :profile}})
                .map(&:student).sort_by do |student|
      sort_name = "#{student.role.last_name} #{student.role.first_name}"
      (sort_name.blank? ? student.role.name : sort_name).downcase
    end.first
  end

  # Make homework assignments due so that their scores are included in the averages
  let(:reports)                       do
    Timecop.freeze(Time.current + 1.1.days) { described_class[course: @course, role: role] }
  end
  let(:first_period_report)           do
    reports.find { |report| report[:period] == first_period }
  end
  let(:second_period_report)          do
    reports.find { |report| report[:period] == second_period }
  end

  context 'non-teacher role' do
    let(:role) { FactoryBot.create :entity_role }

    it 'raises SecurityTransgression' do
      expect{ reports }.to raise_error(SecurityTransgression)
    end
  end

  context 'teacher role' do
    let(:user) { FactoryBot.create :user }
    let(:role) { AddUserAsCourseTeacher[user: FactoryBot.create(:user), course: @course] }

    it 'has the proper structure' do
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

    it 'returns the proper numbers' do
      expect(first_period_report[:overall_average_score]).to be_within(1e-6).of(9/14.0)
      expect(second_period_report[:overall_average_score]).to eq 0.5

      expect(first_period_report[:data_headings][0][:title]).to eq 'Homework 2 task plan'
      expect(first_period_report[:data_headings][0][:plan_id]).to be_a Integer
      expect(first_period_report[:data_headings][0][:type]).to eq 'homework'
      expect(first_period_report[:data_headings][0][:due_at]).to be_a Time
      expect(first_period_report[:data_headings][0][:average_score]).to be_nil
      expect(first_period_report[:data_headings][0][:completion_rate]).to eq 0.5

      expect(second_period_report[:data_headings][0][:title]).to eq 'Homework 2 task plan'
      expect(second_period_report[:data_headings][0][:plan_id]).to be_a Integer
      expect(second_period_report[:data_headings][0][:type]).to eq 'homework'
      expect(second_period_report[:data_headings][0][:due_at]).to be_a Time
      expect(second_period_report[:data_headings][0][:average_score]).to be_nil
      expect(second_period_report[:data_headings][0][:completion_rate]).to eq 0.0

      expect(first_period_report[:data_headings][1][:title]).to eq 'Reading task plan'
      expect(first_period_report[:data_headings][1][:plan_id]).to be_a Integer
      expect(first_period_report[:data_headings][1][:type]).to eq 'reading'
      expect(first_period_report[:data_headings][1][:due_at]).to be_a Time
      expect(first_period_report[:data_headings][1][:average_score]).to be_nil
      expect(first_period_report[:data_headings][1][:completion_rate]).to eq 0.5

      expect(second_period_report[:data_headings][1][:title]).to eq 'Reading task plan'
      expect(second_period_report[:data_headings][1][:plan_id]).to be_a Integer
      expect(second_period_report[:data_headings][1][:type]).to eq 'reading'
      expect(second_period_report[:data_headings][1][:due_at]).to be_a Time
      expect(second_period_report[:data_headings][1][:average_score]).to be_nil
      expect(second_period_report[:data_headings][1][:completion_rate]).to eq 0.0

      expect(first_period_report[:data_headings][2][:title]).to eq 'Homework task plan'
      expect(first_period_report[:data_headings][2][:plan_id]).to be_a Integer
      expect(first_period_report[:data_headings][2][:type]).to eq 'homework'
      expect(first_period_report[:data_headings][2][:due_at]).to be_a Time
      expect(first_period_report[:data_headings][2][:average_score]).to be_within(1e-6).of(9/14.0)
      expect(first_period_report[:data_headings][2][:completion_rate]).to eq 0.5

      expect(second_period_report[:data_headings][2][:title]).to eq 'Homework task plan'
      expect(second_period_report[:data_headings][2][:plan_id]).to be_a Integer
      expect(second_period_report[:data_headings][2][:type]).to eq 'homework'
      expect(second_period_report[:data_headings][2][:due_at]).to be_a Time
      expect(second_period_report[:data_headings][2][:average_score]).to eq 0.5
      expect(second_period_report[:data_headings][2][:completion_rate]).to eq 0.5

      first_period_students = first_period_report[:students]
      expect(first_period_students.map { |student| student[:name] }).to match_array [
        @student_1.name, @student_2.name
      ]
      expect(first_period_students.map { |student| student[:first_name] }).to match_array [
        @student_1.first_name, @student_2.first_name
      ]
      expect(first_period_students.map { |student| student[:last_name] }).to match_array [
        @student_1.last_name, @student_2.last_name
      ]
      expect(first_period_students.map { |student| student[:role] }).to match_array [
        @student_1.to_model.roles.first.id, @student_2.to_model.roles.first.id
      ]
      expect(first_period_students.map { |student| student[:student_identifier] }).to match_array [
        @student_1.to_model.roles.first.student.student_identifier,
        @student_2.to_model.roles.first.student.student_identifier
      ]
      expect(first_period_students.map { |student| student[:average_score] }).to match_array [
        1.0, be_within(1e-6).of(2/7.0)
      ]

      second_period_students = second_period_report[:students]
      expect(second_period_students.map { |student| student[:name] }).to match_array [
        @student_3.name, @student_4.name
      ]
      expect(second_period_students.map { |student| student[:first_name] }).to match_array [
        @student_3.first_name, @student_4.first_name
      ]
      expect(second_period_students.map { |student| student[:last_name] }).to match_array [
        @student_3.last_name, @student_4.last_name
      ]
      expect(second_period_students.map { |student| student[:role] }).to match_array [
        @student_3.to_model.roles.first.id, @student_4.to_model.roles.first.id
      ]
      expect(second_period_students.map { |student| student[:student_identifier] }).to match_array [
        @student_3.to_model.roles.first.student.student_identifier,
        @student_4.to_model.roles.first.student.student_identifier
      ]
      expect(second_period_students.map { |student| student[:average_score] }).to match_array [
        1.0, 0.0
      ]

      (first_period_students + second_period_students).each do |student|
        expect(student[:is_dropped]).to eq false

        data = student[:data]
        expect(data.size).to eq 3
        expect(data.map{ |data| data[:type] }).to eq ['homework', 'reading', 'homework']

        data.each do |data|
          expect(data[:id]).to be_a Integer
          expect(data[:status]).to be_in ['completed', 'in_progress', 'not_started']
          expect(data[:step_count]).to be_a Integer
          expect(data[:completed_step_count]).to be_a Integer
          expect(data[:completed_on_time_step_count]).to be_a Integer
          expect(data[:completed_accepted_late_step_count]).to be_a Integer
          expect(data[:actual_and_placeholder_exercise_count]).to be_a Integer
          expect(data[:completed_exercise_count]).to be_a Integer
          expect(data[:completed_on_time_exercise_count]).to be_a Integer
          expect(data[:completed_accepted_late_exercise_count]).to be_a Integer
          expect(data[:correct_exercise_count]).to be_a Integer
          expect(data[:correct_on_time_exercise_count]).to be_a Integer
          expect(data[:correct_accepted_late_exercise_count]).to be_a Integer
          expect(data[:score]).to be_a Float
          expect(data[:recovered_exercise_count]).to be_a Integer
          expect(data[:due_at]).to be_a Time
          expect(data[:last_worked_at]).to be_nil.or(be_a Time)
          expect(data[:is_late_work_accepted]).to be_in [true, false]
          expect(data[:is_included_in_averages]).to be_in [true, false]
        end
      end
    end

    it 'works after a student has moved period' do
      MoveStudent.call(period: second_period, student: @student_1.to_model.roles.first.student)

      # No need to retest the entire response, just spot check some things that
      # should change when the student moves

      # period 1 no longer has an average score in the data headings (complete tasks moved to
      # period 2; on the other hand, period 2 now has average scores where it didn't before)
      expect(first_period_report[:data_headings][0][:average_score]).to be_nil
      expect(second_period_report[:overall_average_score]).to be_within(1e-6).of(2/3.0)
      expect(second_period_report[:data_headings][2][:average_score]).to be_within(1e-6).of(2/3.0)

      # There should now be 1 student in period 1 and 3 students in period 2
      # whereas before there were 2 in each
      expect(first_period_report[:students].length).to eq 1
      expect(second_period_report[:students].length).to eq 3
    end

    it 'returns nil when a student did not work a particular task' do
      first_student_of_first_period.role.taskings.first.task.really_destroy!
      expect(first_period_report[:students].first[:data]).to include nil
    end

    it 'excludes students that did not get assigned any tasks' do
      first_student_of_first_period.role.taskings.each{ |tasking| tasking.task.really_destroy! }
      expect(reports).not_to include(
        a_hash_including(
          students: a_collection_including(
            a_hash_including(name: first_student_of_first_period.name)
          )
        )
      )
    end

    it 'works when a student was not assigned a particular task' do
      first_student_of_first_period.role.taskings.first.task.destroy
      expect { reports }.not_to raise_error
    end

    it 'works when a student has no first_name' do
      first_student_of_first_period.role.profile.account.update_attribute(:first_name, nil)
      expect { reports }.not_to raise_error
    end

    it 'works when a student has no last_name' do
      first_student_of_first_period.role.profile.account.update_attribute(:last_name, nil)
      expect { reports }.not_to raise_error
    end

    it 'marks dropped students and excludes them from averages' do
      CourseMembership::InactivateStudent.call(student: @student_2.to_model.roles.first.student)

      expect(first_period_report).to include(
        overall_average_score: 1.0,
        students: a_collection_including(a_hash_including(name: @student_2.name, is_dropped: true))
      )
    end
  end
end
