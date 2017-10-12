require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetTpPerformanceReport, type: :routine, speed: :slow do

  before(:all) do
    VCR.use_cassette("Tasks_GetTpPerformanceReport/with_book", VCR_OPTS) do
      @ecosystem = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end
    @course = FactoryGirl.create :course_profile_course, :with_assistants
    CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)

    @teacher = FactoryGirl.create(:user)
    @student_1 = FactoryGirl.create(:user)
    @student_2 = FactoryGirl.create(:user)
    @student_3 = FactoryGirl.create(:user)
    @student_4 = FactoryGirl.create(:user)
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
    Timecop.freeze(Time.current + 1.1.days) { described_class[course: @course] }
  end
  let(:first_period_report)           do
    reports.find { |report| report[:period] == first_period }
  end
  let(:second_period_report)          do
    reports.find { |report| report[:period] == second_period }
  end

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

    #       ],
    #       students: a_collection_containing_exactly(
    #         {
    #           name: @student_2.name,
    #           first_name: @student_2.first_name,
    #           last_name: @student_2.last_name,
    #           role: @student_2.to_model.roles.first,
    #           student_identifier: @student_2.to_model.roles.first.student.student_identifier,
    #           average_score: 1.0,
    #           is_dropped: false,
    #           data: [
    #             {
    #               type: 'homework',
    #               id: kind_of(Integer),
    #               status: 'completed',
    #               step_count: 4,
    #               completed_step_count: 4,
    #               completed_on_time_step_count: 4,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 4,
    #               completed_exercise_count: 4,
    #               completed_on_time_exercise_count: 4,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 3,
    #               correct_on_time_exercise_count: 3,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 0.75,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               last_worked_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: false
    #             },
    #             {
    #               type: 'reading',
    #               id: kind_of(Integer),
    #               status: 'completed',
    #               step_count: 8,
    #               completed_step_count: 8,
    #               completed_on_time_step_count: 8,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 6,
    #               completed_exercise_count: 6,
    #               completed_on_time_exercise_count: 6,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 0,
    #               correct_on_time_exercise_count: 0,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 0.0,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               last_worked_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: false
    #             },
    #             {
    #               type: 'homework',
    #               id: kind_of(Integer),
    #               status: 'completed',
    #               step_count: 6,
    #               completed_step_count: 6,
    #               completed_on_time_step_count: 6,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 6,
    #               completed_exercise_count: 6,
    #               completed_on_time_exercise_count: 6,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 6,
    #               correct_on_time_exercise_count: 6,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 1.0,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               last_worked_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: true
    #             }
    #           ]
    #         },
    #         {
    #           name: @student_1.name,
    #           first_name: @student_1.first_name,
    #           last_name: @student_1.last_name,
    #           role: @student_1.to_model.roles.first,
    #           student_identifier: @student_1.to_model.roles.first.student.student_identifier,
    #           average_score: be_within(1e-6).of(1/3.0),
    #           is_dropped: false,
    #           data: [
    #             {
    #               type: 'homework',
    #               id: kind_of(Integer),
    #               status: 'in_progress',
    #               step_count: 4,
    #               completed_step_count: 1,
    #               completed_on_time_step_count: 1,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 4,
    #               completed_exercise_count: 1,
    #               completed_on_time_exercise_count: 1,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 1,
    #               correct_on_time_exercise_count: 1,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 0.25,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               last_worked_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: false
    #             },
    #             {
    #               type: 'reading',
    #               id: kind_of(Integer),
    #               status: 'in_progress',
    #               step_count: 8,
    #               completed_step_count: 1,
    #               completed_on_time_step_count: 1,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 6,
    #               completed_exercise_count: 0,
    #               completed_on_time_exercise_count: 0,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 0,
    #               correct_on_time_exercise_count: 0,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 0.0,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               last_worked_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: false
    #             },
    #             {
    #               type: 'homework',
    #               id: kind_of(Integer),
    #               status: 'in_progress',
    #               step_count: 6,
    #               completed_step_count: 4,
    #               completed_on_time_step_count: 4,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 6,
    #               completed_exercise_count: 4,
    #               completed_on_time_exercise_count: 4,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 2,
    #               correct_on_time_exercise_count: 2,
    #               correct_accepted_late_exercise_count: 0,
    #               score: be_within(1e-6).of(1/3.0),
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               last_worked_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: true
    #             }
    #           ]
    #         }
    #       )
    #     },
    #     {
    #       period_id: second_period.id.to_s,
    #       overall_average_score: 0.5,
    #       data_headings: [
    #         { title: 'Homework 2 task plan',
    #           plan_id: kind_of(Integer),
    #           type: 'homework',
    #           due_at: kind_of(String),
    #           completion_rate: 0.0
    #         },
    #         { title: 'Reading task plan',
    #           plan_id: kind_of(Integer),
    #           type: 'reading',
    #           due_at: kind_of(String),
    #           completion_rate: 0.0
    #         },
    #         { title: 'Homework task plan',
    #           plan_id: kind_of(Integer),
    #           type: 'homework',
    #           due_at: kind_of(String),
    #           average_score: 0.5,
    #           completion_rate: 0.5
    #         }
    #       ],
    #       students: a_collection_containing_exactly(
    #         {
    #           name: @student_4.name,
    #           first_name: @student_4.first_name,
    #           last_name: @student_4.last_name,
    #           role: @student_4.to_model.roles.first,
    #           student_identifier: @student_4.to_model.roles.first.student.student_identifier,
    #           average_score: 0.0,
    #           is_dropped: false,
    #           data: [
    #             {
    #               type: 'homework',
    #               id: kind_of(Integer),
    #               status: 'not_started',
    #               step_count: 4,
    #               completed_step_count: 0,
    #               completed_on_time_step_count: 0,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 4,
    #               completed_exercise_count: 0,
    #               completed_on_time_exercise_count: 0,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 0,
    #               correct_on_time_exercise_count: 0,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 0.0,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: false
    #             },
    #             {
    #               type: 'reading',
    #               id: kind_of(Integer),
    #               status: 'not_started',
    #               step_count: 8,
    #               completed_step_count: 0,
    #               completed_on_time_step_count: 0,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 6,
    #               completed_exercise_count: 0,
    #               completed_on_time_exercise_count: 0,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 0,
    #               correct_on_time_exercise_count: 0,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 0.0,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: false
    #             },
    #             {
    #               type: 'homework',
    #               id: kind_of(Integer),
    #               status: 'not_started',
    #               step_count: 6,
    #               completed_step_count: 0,
    #               completed_on_time_step_count: 0,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 6,
    #               completed_exercise_count: 0,
    #               completed_on_time_exercise_count: 0,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 0,
    #               correct_on_time_exercise_count: 0,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 0.0,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: true
    #             }
    #           ]
    #         },
    #         {
    #           name: @student_3.name,
    #           first_name: @student_3.first_name,
    #           last_name: @student_3.last_name,
    #           role: @student_3.to_model.roles.first,
    #           student_identifier: @student_3.to_model.roles.first.student.student_identifier,
    #           average_score: 1.0,
    #           is_dropped: false,
    #           data: [
    #             {
    #               type: 'homework',
    #               id: kind_of(Integer),
    #               status: 'not_started',
    #               step_count: 4,
    #               completed_step_count: 0,
    #               completed_on_time_step_count: 0,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 4,
    #               completed_exercise_count: 0,
    #               completed_on_time_exercise_count: 0,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 0,
    #               correct_on_time_exercise_count: 0,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 0.0,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: false
    #             },
    #             {
    #               type: 'reading',
    #               id: kind_of(Integer),
    #               status: 'not_started',
    #               step_count: 8,
    #               completed_step_count: 0,
    #               completed_on_time_step_count: 0,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 6,
    #               completed_exercise_count: 0,
    #               completed_on_time_exercise_count: 0,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 0,
    #               correct_on_time_exercise_count: 0,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 0.0,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: false
    #             },
    #             {
    #               type: 'homework',
    #               id: kind_of(Integer),
    #               status: 'completed',
    #               step_count: 6,
    #               completed_step_count: 6,
    #               completed_on_time_step_count: 6,
    #               completed_accepted_late_step_count: 0,
    #               exercise_count: 6,
    #               completed_exercise_count: 6,
    #               completed_on_time_exercise_count: 6,
    #               completed_accepted_late_exercise_count: 0,
    #               correct_exercise_count: 6,
    #               correct_on_time_exercise_count: 6,
    #               correct_accepted_late_exercise_count: 0,
    #               score: 1.0,
    #               recovered_exercise_count: 0,
    #               due_at: kind_of(String),
    #               last_worked_at: kind_of(String),
    #               is_late_work_accepted: false,
    #               is_included_in_averages: true
    #             }
    #           ]
    #         }
    #       )
    #     }
    #   ]
    # )
  end

  it 'works after a student has moved period' do
    MoveStudent.call(period: second_period, student: @student_1.to_model.roles.first.student)

    # No need to retest the entire response, just spot check some things that
    # should change when the student moves

    # period 1 no longer has an average score in the data headings (complete tasks
    # moved to period 2; on the other hand, period 2 now has average scores where it didn't before)
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
