require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::GetPerformanceReport, type: :routine do
  let(:ecosystem) { FactoryBot.create :mini_ecosystem }
  let(:offering)  { FactoryBot.create :catalog_offering, ecosystem: ecosystem }
  let(:course)    do
    FactoryBot.create :course_profile_course, :with_grading_templates,
                      offering: offering
  end

  before(:each) do
    @teacher = FactoryBot.create(:user_profile)
    @student_1 = FactoryBot.create(:user_profile)
    @student_2 = FactoryBot.create(:user_profile)
    @student_3 = FactoryBot.create(:user_profile)
    @student_4 = FactoryBot.create(:user_profile)

    @teacher_student = FactoryBot.create(:user_profile)

    CreateCourseAssistants.call(course: course)

    SetupPerformanceReportData[
      course: course,
      teacher: @teacher,
      students: [@student_1, @student_2, @student_3, @student_4],
      teacher_students: [@teacher_student],
      ecosystem: ecosystem
    ]

    # External assignment
    external_assistant = course.course_assistants
                                .find_by(tasks_task_plan_type: 'external')
                                .assistant

    external_task_plan = FactoryBot.build(
      :tasks_task_plan,
      title: 'External assignment',
      course: course,
      type: 'external',
      assistant: external_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: { external_url: 'https://www.example.com' },
      num_tasking_plans: 0
    )

    external_task_plan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: course,
      task_plan: external_task_plan,
      opens_at: course.time_zone.now - 5.weeks,
      due_at: course.time_zone.now - 4.weeks,
      closes_at: course.time_zone.now - 3.weeks
    )

    external_task_plan.save!

    DistributeTasks.call(task_plan: external_task_plan)

    homework_assistant = course.course_assistants
                             .find_by(tasks_task_plan_type: 'homework')
                             .assistant


    # Event
    event_assistant = course.course_assistants
                             .find_by(tasks_task_plan_type: 'event')
                             .assistant

    event_task_plan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Event',
      course: course,
      type: 'event',
      assistant: event_assistant,
      content_ecosystem_id: ecosystem.id,
      num_tasking_plans: 0
    )

    event_task_plan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: course,
      task_plan: event_task_plan,
      opens_at: course.time_zone.now - 2.weeks,
      due_at: course.time_zone.now - 1.week,
      closes_at: course.time_zone.now
    )

    event_task_plan.save!

    DistributeTasks.call(task_plan: event_task_plan)

    # Draft assignment, not included in the scores
    reading_assistant = course.course_assistants
                               .find_by(tasks_task_plan_type: 'reading')
                               .assistant

    draft_task_plan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Draft task plan',
      course: course,
      type: 'reading',
      assistant: reading_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: { page_ids: ecosystem.pages.first(2).map(&:id).map(&:to_s) },
      num_tasking_plans: 0
    )

    draft_task_plan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: course,
      task_plan: draft_task_plan,
      opens_at: course.time_zone.now - 1.week,
      due_at: course.time_zone.now,
      closes_at: course.time_zone.now + 1.week
    )

    draft_task_plan.save!

    # Create the preview task, which might interfere with the scores
    DistributeTasks.call(task_plan: draft_task_plan, preview: true)
  end

  before do
    course.reload
    @student_1.reload
    @student_2.reload
  end

  # Make homework assignments due so that their scores are included in the averages
  let(:reports) do
    Timecop.freeze(Time.current + 1.1.days) { described_class[course: course, role: role] }
  end

  context 'teacher' do
    let(:role)                          { @teacher.roles.first }

    let(:expected_periods)              { 2 }
    let(:expected_students)             { 2 }

    let(:expected_task_types)           { ['homework', 'reading', 'homework', 'external'] }
    let(:expected_tasks)                { expected_task_types.size }

    let(:first_period)                  { course.periods.order(:created_at).first }
    let(:second_period)                 { course.periods.order(:created_at).second }
    let(:first_student_of_first_period) do
      first_period.students.preload(role: :profile).sort_by do |student|
        sort_name = "#{student.role.last_name} #{student.role.first_name}"
        (sort_name.blank? ? student.role.name : sort_name).downcase
      end.first
    end

    let(:first_period_report)  { reports.find { |report| report.period == first_period } }
    let(:second_period_report) { reports.find { |report| report.period == second_period } }

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

    context 'ended course with a frozen performance report' do
      before do
        FactoryBot.create(
          :course_profile_cache,
          course: course,
          teacher_performance_report: [ { is_frozen: true } ]
        )
        course.ends_at = Time.current
        course.save validate: false
      end

      it 'returns the frozen performance report instead' do
        expect(reports.first.is_frozen).to eq true
      end
    end

    context 'immediate feedback' do
      before do
        Tasks::Models::GradingTemplate.find_each do |grading_template|
          grading_template.update_columns(
            auto_grading_feedback_on: :answer,
            manual_grading_feedback_on: :grade,
            late_work_penalty: 0.0
          )
        end
        Tasks::Models::Task.preload(task_steps: :tasked).find_each do |task|
          task.update_cached_attributes.save validate: false
        end
      end

      it 'returns the proper numbers' do
        hw_score = ((1.0 + 0.75)/2 + (2.0/7.0 + 0.25)/2)/2
        expect(first_period_report.overall_homework_score).to be_within(1e-6).of(
          hw_score
        )
        expect(first_period_report.overall_homework_progress).to be_within(1e-6).of(
          (1.0 + (4.0/7.0 + 0.25)/2)/2
        )
        rd_score = 0.45
        expect(first_period_report.overall_reading_score).to be_within(1e-6).of(rd_score)

        expect(first_period_report.overall_reading_progress).to be_within(1e-6).of(
          first_period_report['students'].sum(&:reading_progress) / first_period_report['students'].length
        )

        expect(first_period_report.overall_course_average).to be_within(1e-6).of(
          (hw_score * course.homework_weight) + (rd_score * course.reading_weight)
        )

        expect(second_period_report.overall_homework_score).to eq 0.25
        expect(second_period_report.overall_homework_progress).to eq 0.25
        expect(second_period_report.overall_reading_score).to eq 0.0
        expect(second_period_report.overall_reading_progress).to eq 0.0
        expect(second_period_report.overall_course_average).to eq 0.125

        expect(first_period_report.data_headings[0].title).to eq 'Homework 2 task plan'
        expect(first_period_report.data_headings[0].plan_id).to be_a Integer
        expect(first_period_report.data_headings[0].type).to eq 'homework'
        expect(first_period_report.data_headings[0].due_at).to be_a Time
        expect(first_period_report.data_headings[0].average_score).to eq 0.5
        expect(first_period_report.data_headings[0].average_progress).to eq 0.625

        expect(second_period_report.data_headings[0].title).to eq 'Homework 2 task plan'
        expect(second_period_report.data_headings[0].plan_id).to be_a Integer
        expect(second_period_report.data_headings[0].type).to eq 'homework'
        expect(second_period_report.data_headings[0].due_at).to be_a Time
        expect(second_period_report.data_headings[0].average_score).to eq 0.0
        expect(second_period_report.data_headings[0].average_progress).to eq 0.0

        expect(first_period_report.data_headings[1].title).to eq 'Reading task plan'
        expect(first_period_report.data_headings[1].plan_id).to be_a Integer
        expect(first_period_report.data_headings[1].type).to eq 'reading'
        expect(first_period_report.data_headings[1].due_at).to be_a Time
        expect(first_period_report.data_headings[1].average_score).to be_within(1e-6).of(0.45)
        expect(first_period_report.data_headings[1].average_progress).to eq(
          first_period_report['students'].sum(&:reading_progress) / first_period_report['students'].length
        )

        expect(second_period_report.data_headings[1].title).to eq 'Reading task plan'
        expect(second_period_report.data_headings[1].plan_id).to be_a Integer
        expect(second_period_report.data_headings[1].type).to eq 'reading'
        expect(second_period_report.data_headings[1].due_at).to be_a Time
        expect(second_period_report.data_headings[1].average_score).to eq 0.0
        expect(second_period_report.data_headings[1].average_progress).to eq 0.0

        expect(first_period_report.data_headings[2].title).to eq 'Homework task plan'
        expect(first_period_report.data_headings[2].plan_id).to be_a Integer
        expect(first_period_report.data_headings[2].type).to eq 'homework'
        expect(first_period_report.data_headings[2].due_at).to be_a Time
        expect(first_period_report.data_headings[2].average_score).to be_within(1e-6).of(9/14.0)
        expect(first_period_report.data_headings[2].average_progress).to be_within(1e-6).of(11/14.0)

        expect(second_period_report.data_headings[2].title).to eq 'Homework task plan'
        expect(second_period_report.data_headings[2].plan_id).to be_a Integer
        expect(second_period_report.data_headings[2].type).to eq 'homework'
        expect(second_period_report.data_headings[2].due_at).to be_a Time
        expect(second_period_report.data_headings[2].average_score).to eq 0.5
        expect(second_period_report.data_headings[2].average_progress).to eq 0.5

        expect(first_period_report.data_headings[3].title).to eq 'External assignment'
        expect(first_period_report.data_headings[3].plan_id).to be_a Integer
        expect(first_period_report.data_headings[3].type).to eq 'external'
        expect(first_period_report.data_headings[3].due_at).to be_a Time
        expect(first_period_report.data_headings[3].average_score).to be_nil
        expect(first_period_report.data_headings[3].average_progress).to eq 0.0

        expect(second_period_report.data_headings[3].title).to eq 'External assignment'
        expect(second_period_report.data_headings[3].plan_id).to be_a Integer
        expect(second_period_report.data_headings[3].type).to eq 'external'
        expect(second_period_report.data_headings[3].due_at).to be_a Time
        expect(second_period_report.data_headings[3].average_score).to be_nil
        expect(second_period_report.data_headings[3].average_progress).to eq 0.0

        first_period_students = first_period_report.students
        expect(first_period_students.map(&:name)).to match_array [
          @student_1.name, @student_2.name
        ]
        expect(first_period_students.map(&:first_name)).to match_array [
          @student_1.first_name, @student_2.first_name
        ]
        expect(first_period_students.map(&:last_name)).to match_array [
          @student_1.last_name, @student_2.last_name
        ]
        expect(first_period_students.map(&:role)).to match_array [
          @student_1.roles.first.id, @student_2.roles.first.id
        ]
        expect(first_period_students.map(&:student_identifier)).to match_array [
          @student_1.roles.first.student.student_identifier,
          @student_2.roles.first.student.student_identifier
        ]
        expect(first_period_students.map(&:homework_score)).to match_array [
          be_within(1e-6).of((1.0 + 0.75)/2), be_within(1e-6).of((2.0/7.0 + 0.25)/2)
        ]
        expect(first_period_students.map(&:homework_progress)).to match_array [
          1.0, be_within(1e-6).of((4.0/7.0 + 0.25)/2)
        ]
        expect(first_period_students.map(&:reading_score)).to match_array [
          be_within(1e-6).of(0.9), 0.0
        ]
        expect(first_period_students.map(&:reading_progress)).to match_array [
          0.058823529411764705, 1.0
        ]

        expect(first_period_students.map(&:course_average)).to eq(
          first_period_students.map{ |s|
            (s.homework_score * course.homework_weight) +
              (s.reading_score * course.reading_weight)
          }
        )

        second_period_students = second_period_report.students
        expect(second_period_students.map(&:name)).to match_array [
          @student_3.name, @student_4.name
        ]
        expect(second_period_students.map(&:first_name)).to match_array [
          @student_3.first_name, @student_4.first_name
        ]
        expect(second_period_students.map(&:last_name)).to match_array [
          @student_3.last_name, @student_4.last_name
        ]
        expect(second_period_students.map(&:role)).to match_array [
          @student_3.roles.first.id, @student_4.roles.first.id
        ]
        expect(second_period_students.map(&:student_identifier)).to match_array [
          @student_3.roles.first.student.student_identifier,
          @student_4.roles.first.student.student_identifier
        ]
        expect(second_period_students.map(&:homework_score)).to match_array [ 0.5, 0.0 ]
        expect(second_period_students.map(&:homework_progress)).to match_array [ 0.5, 0.0 ]
        expect(second_period_students.map(&:reading_score)).to match_array [ 0.0, 0.0 ]
        expect(second_period_students.map(&:reading_progress)).to match_array [ 0.0, 0.0 ]
        expect(second_period_students.map(&:course_average)).to eq(
          second_period_students.map{ |s|
            (s.homework_score * course.homework_weight) +
              (s.reading_score * course.reading_weight)
          }
        )

        (first_period_students + second_period_students).each do |student|
          expect(student.is_dropped).to eq false

          data = student.data
          expect(data.size).to eq expected_tasks
          expect(data.map(&:type)).to eq expected_task_types

          data.each do |data|
            expect(data.id).to be_a Integer
            expect(data.status).to be_in ['completed', 'in_progress', 'not_started']
            expect(data.due_at).to be_a Time
            expect(data.step_count).to be_a Integer
            expect(data.completed_step_count).to be_a Integer
            expect(data.progress).to be_a Float
            # Some assignments might not have feedback available
            # so they might get a nil here even though points/score have been assigned
            expect(data.published_points.class).to be_in([NilClass, Float])
            expect(data.published_score.class).to be_in([NilClass, Float])
          end
        end
      end

      it 'works after a student has moved to a different period' do
        MoveStudent.call(period: second_period, student: @student_1.roles.first.student)

        # No need to retest the entire response, just spot check some things that
        # should change when the student moves
        expect(first_period_report.overall_homework_score).to be_within(1e-6).of((2/7.0 + 0.25)/2)
        expect(first_period_report.overall_homework_progress).to be_within(1e-6).of(
          (4.0/7.0 + 0.25)/2
        )
        expect(first_period_report.overall_reading_score).to eq 0.0
        expect(first_period_report.overall_reading_progress).to eq(
          first_period_report['students'].sum(&:reading_progress) / first_period_report['students'].length
        )
        expect(first_period_report.overall_course_average).to eq(
          first_period_report.students.sum{ |s|
            (s.homework_score * course.homework_weight) +
              (s.reading_score * course.reading_weight)
          } / first_period_report.students.length
        )
        expect(first_period_report.data_headings[0].average_score).to eq 0.25

        expect(second_period_report.overall_homework_score).to be_within(1e-6).of(
          ((1.0 + 0.75)/2 + 0.5)/3
        )
        expect(second_period_report.overall_homework_progress).to eq 0.5
        expect(second_period_report.overall_reading_score).to eq 0.3
        expect(second_period_report.overall_reading_progress).to be_within(1e-6).of(1.0/3.0)
        expect(second_period_report.overall_course_average).to eq(
          second_period_report.students.sum{ |s|
            (s.homework_score * course.homework_weight) +
              (s.reading_score * course.reading_weight)
          } / second_period_report.students.length
        )
        expect(second_period_report.data_headings[2].average_score).to be_within(1e-6).of(2/3.0)

        # There should now be 1 student in period 1 and 3 students in period 2
        # whereas before there were 2 in each
        expect(first_period_report.students.length).to eq 1
        expect(second_period_report.students.length).to eq 3
      end

      it 'marks dropped students and excludes them from averages' do
        CourseMembership::InactivateStudent.call(student: @student_2.roles.first.student)

        expect(first_period_report.overall_homework_score).to be_within(1e-6).of((1.0 + 0.75)/2)
        expect(first_period_report.overall_homework_progress).to eq 1.0
        expect(first_period_report.overall_reading_score).to be_within(1e-6).of(0.9)
        expect(first_period_report.overall_reading_progress).to eq 1.0
        expect(first_period_report.overall_course_average).to eq(
          first_period_report.overall_homework_score * course.homework_weight +
            first_period_report.overall_reading_score * course.reading_weight
        )
        expect(first_period_report.students.any? do |student|
          student.name == @student_2.name && student.is_dropped
        end).to eq true
      end

      it 'ignores the weights when calculating averages if one assignment type is missing' do
        current_time = Time.current
        Tasks::Models::Task.where(task_type: 'homework').update_all(
          due_at_ntz: current_time + 1.day, closes_at_ntz: current_time + 2.days
        )
        expect(first_period_report.overall_homework_score).to be_nil
        expect(first_period_report.overall_homework_progress).to be_nil
        rd_score = 0.45
        expect(first_period_report.overall_reading_score).to be_within(1e-6).of(rd_score)
        expect(first_period_report.overall_reading_progress).to be_within(1e-6).of(
          first_period_report['students'].sum(&:reading_progress) / first_period_report['students'].length
        )

        expect(first_period_report.overall_course_average).to be_within(1e-6).of(rd_score)

        expect(second_period_report.overall_homework_score).to be_nil
        expect(second_period_report.overall_homework_progress).to be_nil
        expect(second_period_report.overall_reading_score).to eq 0.0
        expect(second_period_report.overall_reading_progress).to eq 0.0
        expect(second_period_report.overall_course_average).to eq 0.0

        expect(first_period_report.data_headings[0].title).to eq 'Reading task plan'
        expect(first_period_report.data_headings[0].plan_id).to be_a Integer
        expect(first_period_report.data_headings[0].type).to eq 'reading'
        expect(first_period_report.data_headings[0].due_at).to be_a Time
        expect(first_period_report.data_headings[0].average_score).to be_within(1e-6).of(0.45)
        expect(first_period_report.data_headings[0].average_progress).to eq(
          first_period_report['students'].sum(&:reading_progress) / first_period_report['students'].length
        )

        expect(second_period_report.data_headings[0].title).to eq 'Reading task plan'
        expect(second_period_report.data_headings[0].plan_id).to be_a Integer
        expect(second_period_report.data_headings[0].type).to eq 'reading'
        expect(second_period_report.data_headings[0].due_at).to be_a Time
        expect(second_period_report.data_headings[0].average_score).to eq 0.0
        expect(second_period_report.data_headings[0].average_progress).to eq 0.0

        expect(first_period_report.data_headings[1].title).to eq 'External assignment'
        expect(first_period_report.data_headings[1].plan_id).to be_a Integer
        expect(first_period_report.data_headings[1].type).to eq 'external'
        expect(first_period_report.data_headings[1].due_at).to be_a Time
        expect(first_period_report.data_headings[1].average_score).to be_nil
        expect(first_period_report.data_headings[1].average_progress).to eq 0.0

        expect(second_period_report.data_headings[1].title).to eq 'External assignment'
        expect(second_period_report.data_headings[1].plan_id).to be_a Integer
        expect(second_period_report.data_headings[1].type).to eq 'external'
        expect(second_period_report.data_headings[1].due_at).to be_a Time
        expect(second_period_report.data_headings[1].average_score).to be_nil
        expect(second_period_report.data_headings[1].average_progress).to eq 0.0

        first_period_students = first_period_report.students
        expect(first_period_students.map(&:name)).to match_array [
          @student_1.name, @student_2.name
        ]
        expect(first_period_students.map(&:first_name)).to match_array [
          @student_1.first_name, @student_2.first_name
        ]
        expect(first_period_students.map(&:last_name)).to match_array [
          @student_1.last_name, @student_2.last_name
        ]
        expect(first_period_students.map(&:role)).to match_array [
          @student_1.roles.first.id, @student_2.roles.first.id
        ]
        expect(first_period_students.map(&:student_identifier)).to match_array [
          @student_1.roles.first.student.student_identifier,
          @student_2.roles.first.student.student_identifier
        ]
        expect(first_period_students.map(&:homework_score)).to eq [ nil, nil ]
        expect(first_period_students.map(&:homework_progress)).to eq [ nil, nil ]
        expect(first_period_students.map(&:reading_score)).to match_array [
          be_within(1e-6).of(0.9), 0.0
        ]
        expect(first_period_students.map(&:reading_progress)).to match_array [
          0.058823529411764705, 1.0
        ]

        expect(first_period_students.map(&:course_average)).to eq(
          first_period_students.map(&:reading_score)
        )

        second_period_students = second_period_report.students
        expect(second_period_students.map(&:name)).to match_array [
          @student_3.name, @student_4.name
        ]
        expect(second_period_students.map(&:first_name)).to match_array [
          @student_3.first_name, @student_4.first_name
        ]
        expect(second_period_students.map(&:last_name)).to match_array [
          @student_3.last_name, @student_4.last_name
        ]
        expect(second_period_students.map(&:role)).to match_array [
          @student_3.roles.first.id, @student_4.roles.first.id
        ]
        expect(second_period_students.map(&:student_identifier)).to match_array [
          @student_3.roles.first.student.student_identifier,
          @student_4.roles.first.student.student_identifier
        ]
        expect(second_period_students.map(&:homework_score)).to eq [ nil, nil ]
        expect(second_period_students.map(&:homework_progress)).to eq [ nil, nil ]
        expect(second_period_students.map(&:reading_score)).to eq [ 0.0, 0.0 ]
        expect(second_period_students.map(&:reading_progress)).to eq [ 0.0, 0.0 ]
        expect(second_period_students.map(&:course_average)).to eq(
          second_period_students.map(&:reading_score)
        )

        (first_period_students + second_period_students).each do |student|
          expect(student.is_dropped).to eq false

          data = student.data
          expect(data.size).to eq 2
          expect(data.map(&:type)).to eq [ 'reading', 'external' ]

          data.each do |data|
            expect(data.id).to be_a Integer
            expect(data.status).to be_in ['completed', 'in_progress', 'not_started']
            expect(data.due_at).to be_a Time
            expect(data.step_count).to be_a Integer
            expect(data.completed_step_count).to be_a Integer
            expect(data.progress).to be_a Float
            # Some assignments might not have feedback available
            # so they might get a nil here even though points/score have been assigned
            expect(data.published_points.class).to be_in([NilClass, Float])
            expect(data.published_score.class).to be_in([NilClass, Float])
          end
        end
      end
    end

    context 'feedback on due date' do
      before do
        Tasks::Models::GradingTemplate.find_each do |grading_template|
          grading_template.update_columns(
            auto_grading_feedback_on: :due,
            manual_grading_feedback_on: :grade,
            late_work_penalty: 0.0
          )
        end
        Tasks::Models::Task.preload(task_steps: :tasked).find_each do |task|
          task.update_cached_attributes.save validate: false
        end
      end

      it 'returns the proper numbers' do
        expect(first_period_report.overall_homework_score).to be_within(1e-6).of(
          ((1.0 + 0.75)/2 + (2.0/7.0 + 0.25)/2)/2
        )
        expect(first_period_report.overall_homework_progress).to be_within(1e-6).of(
          first_period_report['students'].sum(&:homework_progress) / first_period_report['students'].length
        )
        expect(first_period_report.overall_reading_score).to be_within(1e-6).of(0.45)
        expect(first_period_report.overall_reading_progress).to be_within(1e-6).of(
          first_period_report['students'].sum(&:reading_progress) / first_period_report['students'].length
        )
        expect(first_period_report.overall_course_average).to eq(
          first_period_report.overall_homework_score * course.homework_weight +
            first_period_report.overall_reading_score * course.reading_weight
        )

        expect(second_period_report.overall_homework_score).to eq 0.25
        expect(second_period_report.overall_homework_progress).to eq 0.25
        expect(second_period_report.overall_reading_score).to eq 0.0
        expect(second_period_report.overall_reading_progress).to eq 0.0
        expect(second_period_report.overall_course_average).to eq 0.125

        expect(first_period_report.data_headings[0].title).to eq 'Homework 2 task plan'
        expect(first_period_report.data_headings[0].plan_id).to be_a Integer
        expect(first_period_report.data_headings[0].type).to eq 'homework'
        expect(first_period_report.data_headings[0].due_at).to be_a Time
        expect(first_period_report.data_headings[0].average_score).to eq 0.5
        expect(first_period_report.data_headings[0].average_progress).to eq 0.625

        expect(second_period_report.data_headings[0].title).to eq 'Homework 2 task plan'
        expect(second_period_report.data_headings[0].plan_id).to be_a Integer
        expect(second_period_report.data_headings[0].type).to eq 'homework'
        expect(second_period_report.data_headings[0].due_at).to be_a Time
        expect(second_period_report.data_headings[0].average_score).to eq 0.0
        expect(second_period_report.data_headings[0].average_progress).to eq 0.0

        expect(first_period_report.data_headings[1].title).to eq 'Reading task plan'
        expect(first_period_report.data_headings[1].plan_id).to be_a Integer
        expect(first_period_report.data_headings[1].type).to eq 'reading'
        expect(first_period_report.data_headings[1].due_at).to be_a Time
        expect(first_period_report.data_headings[1].average_score).to be_within(1e-6).of(0.45)

        expect(first_period_report.data_headings[1].average_progress).to eq(
          first_period_report['students'].sum{ |s| s['data'][1]['progress'] } /
            first_period_report['students'].length
        )

        expect(second_period_report.data_headings[1].title).to eq 'Reading task plan'
        expect(second_period_report.data_headings[1].plan_id).to be_a Integer
        expect(second_period_report.data_headings[1].type).to eq 'reading'
        expect(second_period_report.data_headings[1].due_at).to be_a Time
        expect(second_period_report.data_headings[1].average_score).to eq 0.0
        expect(second_period_report.data_headings[1].average_progress).to eq 0.0

        expect(first_period_report.data_headings[2].title).to eq 'Homework task plan'
        expect(first_period_report.data_headings[2].plan_id).to be_a Integer
        expect(first_period_report.data_headings[2].type).to eq 'homework'
        expect(first_period_report.data_headings[2].due_at).to be_a Time
        expect(first_period_report.data_headings[2].average_score).to be_within(1e-6).of(9/14.0)
        expect(first_period_report.data_headings[2].average_progress).to be_within(1e-6).of(11/14.0)

        expect(second_period_report.data_headings[2].title).to eq 'Homework task plan'
        expect(second_period_report.data_headings[2].plan_id).to be_a Integer
        expect(second_period_report.data_headings[2].type).to eq 'homework'
        expect(second_period_report.data_headings[2].due_at).to be_a Time
        expect(second_period_report.data_headings[2].average_score).to eq 0.5
        expect(second_period_report.data_headings[2].average_progress).to eq 0.5

        expect(first_period_report.data_headings[3].title).to eq 'External assignment'
        expect(first_period_report.data_headings[3].plan_id).to be_a Integer
        expect(first_period_report.data_headings[3].type).to eq 'external'
        expect(first_period_report.data_headings[3].due_at).to be_a Time
        expect(first_period_report.data_headings[3].average_score).to be_nil
        expect(first_period_report.data_headings[3].average_progress).to eq 0.0

        expect(second_period_report.data_headings[3].title).to eq 'External assignment'
        expect(second_period_report.data_headings[3].plan_id).to be_a Integer
        expect(second_period_report.data_headings[3].type).to eq 'external'
        expect(second_period_report.data_headings[3].due_at).to be_a Time
        expect(second_period_report.data_headings[3].average_score).to be_nil
        expect(second_period_report.data_headings[3].average_progress).to eq 0.0

        first_period_students = first_period_report.students
        expect(first_period_students.map(&:name)).to match_array [
          @student_1.name, @student_2.name
        ]
        expect(first_period_students.map(&:first_name)).to match_array [
          @student_1.first_name, @student_2.first_name
        ]
        expect(first_period_students.map(&:last_name)).to match_array [
          @student_1.last_name, @student_2.last_name
        ]
        expect(first_period_students.map(&:role)).to match_array [
          @student_1.roles.first.id, @student_2.roles.first.id
        ]
        expect(first_period_students.map(&:student_identifier)).to match_array [
          @student_1.roles.first.student.student_identifier,
          @student_2.roles.first.student.student_identifier
        ]
        expect(first_period_students.map(&:homework_score)).to match_array [
          be_within(1e-6).of((1.0 + 0.75)/2), be_within(1e-6).of((2.0/7.0 + 0.25)/2)
        ]
        expect(first_period_students.map(&:homework_progress)).to match_array [
          1.0, be_within(1e-6).of((4.0/7.0 + 0.25)/2)
        ]
        expect(first_period_students.map(&:reading_score)).to match_array [
          be_within(1e-6).of(0.9), 0.0
        ]
        expect(first_period_students.map(&:reading_progress)).to match_array [
          0.058823529411764705, 1.0
        ]
        expect(first_period_students.map(&:course_average)).to eq(
          first_period_report.students.map{ |s|
            (s.homework_score * course.homework_weight) +
              (s.reading_score * course.reading_weight)
          }
        )

        second_period_students = second_period_report.students
        expect(second_period_students.map(&:name)).to match_array [
          @student_3.name, @student_4.name
        ]
        expect(second_period_students.map(&:first_name)).to match_array [
          @student_3.first_name, @student_4.first_name
        ]
        expect(second_period_students.map(&:last_name)).to match_array [
          @student_3.last_name, @student_4.last_name
        ]
        expect(second_period_students.map(&:role)).to match_array [
          @student_3.roles.first.id, @student_4.roles.first.id
        ]
        expect(second_period_students.map(&:student_identifier)).to match_array [
          @student_3.roles.first.student.student_identifier,
          @student_4.roles.first.student.student_identifier
        ]
        expect(second_period_students.map(&:homework_score)).to match_array [ 0.5, 0.0 ]
        expect(second_period_students.map(&:homework_progress)).to match_array [ 0.5, 0.0 ]
        expect(second_period_students.map(&:reading_score)).to match_array [ 0.0, 0.0 ]
        expect(second_period_students.map(&:reading_progress)).to match_array [ 0.0, 0.0 ]
        expect(second_period_students.map(&:course_average)).to eq(
          second_period_report.students.map{ |s|
            (s.homework_score * course.homework_weight) +
              (s.reading_score * course.reading_weight)
          }
        )

        (first_period_students + second_period_students).each do |student|
          expect(student.is_dropped).to eq false

          data = student.data
          expect(data.size).to eq expected_tasks
          expect(data.map(&:type)).to eq expected_task_types

          data.each do |data|
            expect(data.id).to be_a Integer
            expect(data.status).to be_in ['completed', 'in_progress', 'not_started']
            expect(data.due_at).to be_a Time
            expect(data.step_count).to be_a Integer
            expect(data.completed_step_count).to be_a Integer
            expect(data.progress).to be_a Float
            # Some assignments might not have feedback available
            # so they might get a nil here even though points/score have been assigned
            expect(data.published_points.class).to be_in([NilClass, Float])
            expect(data.published_score.class).to be_in([NilClass, Float])
          end
        end
      end
    end

    context 'feedback on publish' do
      before do
        Tasks::Models::GradingTemplate.find_each do |grading_template|
          grading_template.update_columns(
            auto_grading_feedback_on: :publish,
            manual_grading_feedback_on: :publish,
            late_work_penalty: 0.0
          )
        end
        Tasks::Models::Task.preload(task_steps: :tasked).find_each do |task|
          task.update_cached_attributes.save validate: false
        end
      end

      it 'returns the proper numbers' do
        expect(first_period_report.overall_homework_score).to eq 0.0
        expect(first_period_report.overall_homework_progress).to be_within(1e-6).of(
          (1.0 + (4.0/7.0 + 0.25)/2)/2
        )
        expect(first_period_report.overall_reading_score).to eq 0.0

        expect(first_period_report.overall_reading_progress).to be_within(1e-6).of(
          first_period_report['students'].sum(&:reading_progress) / first_period_report['students'].length
        )
        expect(first_period_report.overall_course_average).to eq(
          first_period_report.overall_homework_score
        )

        expect(second_period_report.overall_homework_score).to eq 0.0
        expect(second_period_report.overall_homework_progress).to eq 0.25
        expect(second_period_report.overall_reading_score).to eq 0.0
        expect(second_period_report.overall_reading_progress).to eq 0.0
        expect(second_period_report.overall_course_average).to eq 0.0

        expect(first_period_report.data_headings[0].title).to eq 'Homework 2 task plan'
        expect(first_period_report.data_headings[0].plan_id).to be_a Integer
        expect(first_period_report.data_headings[0].type).to eq 'homework'
        expect(first_period_report.data_headings[0].due_at).to be_a Time
        expect(first_period_report.data_headings[0].average_score).to eq 0.0
        expect(first_period_report.data_headings[0].average_progress).to eq 0.625

        expect(second_period_report.data_headings[0].title).to eq 'Homework 2 task plan'
        expect(second_period_report.data_headings[0].plan_id).to be_a Integer
        expect(second_period_report.data_headings[0].type).to eq 'homework'
        expect(second_period_report.data_headings[0].due_at).to be_a Time
        expect(second_period_report.data_headings[0].average_score).to eq 0.0
        expect(second_period_report.data_headings[0].average_progress).to eq 0.0

        expect(first_period_report.data_headings[1].title).to eq 'Reading task plan'
        expect(first_period_report.data_headings[1].plan_id).to be_a Integer
        expect(first_period_report.data_headings[1].type).to eq 'reading'
        expect(first_period_report.data_headings[1].due_at).to be_a Time
        expect(first_period_report.data_headings[1].average_score).to eq 0.0
        expect(first_period_report.data_headings[1].average_progress).to eq(
          first_period_report['students'].sum{ |s| s['data'][1]['progress'] } /
            first_period_report['students'].length
        )

        expect(second_period_report.data_headings[1].title).to eq 'Reading task plan'
        expect(second_period_report.data_headings[1].plan_id).to be_a Integer
        expect(second_period_report.data_headings[1].type).to eq 'reading'
        expect(second_period_report.data_headings[1].due_at).to be_a Time
        expect(second_period_report.data_headings[1].average_score).to eq 0.0
        expect(second_period_report.data_headings[1].average_progress).to eq 0.0

        expect(first_period_report.data_headings[2].title).to eq 'Homework task plan'
        expect(first_period_report.data_headings[2].plan_id).to be_a Integer
        expect(first_period_report.data_headings[2].type).to eq 'homework'
        expect(first_period_report.data_headings[2].due_at).to be_a Time
        expect(first_period_report.data_headings[2].average_score).to be_nil
        expect(first_period_report.data_headings[2].average_progress).to be_within(1e-6).of(11/14.0)

        expect(second_period_report.data_headings[2].title).to eq 'Homework task plan'
        expect(second_period_report.data_headings[2].plan_id).to be_a Integer
        expect(second_period_report.data_headings[2].type).to eq 'homework'
        expect(second_period_report.data_headings[2].due_at).to be_a Time
        expect(second_period_report.data_headings[2].average_score).to eq 0.0
        expect(second_period_report.data_headings[2].average_progress).to eq 0.5

        expect(first_period_report.data_headings[3].title).to eq 'External assignment'
        expect(first_period_report.data_headings[3].plan_id).to be_a Integer
        expect(first_period_report.data_headings[3].type).to eq 'external'
        expect(first_period_report.data_headings[3].due_at).to be_a Time
        expect(first_period_report.data_headings[3].average_score).to be_nil
        expect(first_period_report.data_headings[3].average_progress).to eq 0.0

        expect(second_period_report.data_headings[3].title).to eq 'External assignment'
        expect(second_period_report.data_headings[3].plan_id).to be_a Integer
        expect(second_period_report.data_headings[3].type).to eq 'external'
        expect(second_period_report.data_headings[3].due_at).to be_a Time
        expect(second_period_report.data_headings[3].average_score).to be_nil
        expect(second_period_report.data_headings[3].average_progress).to eq 0.0

        first_period_students = first_period_report.students
        expect(first_period_students.map(&:name)).to match_array [
          @student_1.name, @student_2.name
        ]
        expect(first_period_students.map(&:first_name)).to match_array [
          @student_1.first_name, @student_2.first_name
        ]
        expect(first_period_students.map(&:last_name)).to match_array [
          @student_1.last_name, @student_2.last_name
        ]
        expect(first_period_students.map(&:role)).to match_array [
          @student_1.roles.first.id, @student_2.roles.first.id
        ]
        expect(first_period_students.map(&:student_identifier)).to match_array [
          @student_1.roles.first.student.student_identifier,
          @student_2.roles.first.student.student_identifier
        ]
        expect(first_period_students.map(&:homework_score)).to match_array [
          0.0, nil
        ]
        expect(first_period_students.map(&:homework_progress)).to match_array [
          1.0, be_within(1e-6).of((4.0/7.0 + 0.25)/2)
        ]
        expect(first_period_students.map(&:reading_score)).to match_array [
          0.0, nil
        ]
        expect(first_period_students.map(&:reading_progress)).to match_array [
          0.058823529411764705, 1.0
        ]

        expect(first_period_students.map(&:course_average)).to  match_array [
          0.0, nil,
        ]

        second_period_students = second_period_report.students
        expect(second_period_students.map(&:name)).to match_array [
          @student_3.name, @student_4.name
        ]
        expect(second_period_students.map(&:first_name)).to match_array [
          @student_3.first_name, @student_4.first_name
        ]
        expect(second_period_students.map(&:last_name)).to match_array [
          @student_3.last_name, @student_4.last_name
        ]
        expect(second_period_students.map(&:role)).to match_array [
          @student_3.roles.first.id, @student_4.roles.first.id
        ]
        expect(second_period_students.map(&:student_identifier)).to match_array [
          @student_3.roles.first.student.student_identifier,
          @student_4.roles.first.student.student_identifier
        ]
        expect(second_period_students.map(&:homework_score)).to match_array [ 0.0, 0.0 ]
        expect(second_period_students.map(&:homework_progress)).to match_array [ 0.5, 0.0 ]
        expect(second_period_students.map(&:reading_score)).to match_array [ 0.0, 0.0 ]
        expect(second_period_students.map(&:reading_progress)).to match_array [ 0.0, 0.0 ]
        expect(second_period_students.map(&:course_average)).to eq(
          second_period_students.map(&:homework_score)
        )

        (first_period_students + second_period_students).each do |student|
          expect(student.is_dropped).to eq false

          data = student.data
          expect(data.size).to eq expected_tasks
          expect(data.map(&:type)).to eq expected_task_types

          data.each do |data|
            expect(data.id).to be_a Integer
            expect(data.status).to be_in ['completed', 'in_progress', 'not_started']
            expect(data.due_at).to be_a Time
            expect(data.step_count).to be_a Integer
            expect(data.completed_step_count).to be_a Integer
            expect(data.progress).to be_a Float
            # Some assignments might not have feedback available
            # so they might get a nil here even though points/score have been assigned
            expect(data.published_points.class).to be_in([NilClass, Float])
            expect(data.published_score.class).to be_in([NilClass, Float])
          end
        end
      end
    end

    it 'returns nil when a student did not work a particular task' do
      first_student_of_first_period.role.taskings.first.task.really_destroy!
      expect(first_period_report.students.first.data).to include nil
    end

    it 'includes all students in the period, even if they did not get assigned any tasks' do
      first_student_of_first_period.role.taskings.each { |tasking| tasking.task.really_destroy! }
      expect(first_period_report.students.map(&:name)).to include first_student_of_first_period.name
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
  end

  context 'student' do
    let(:role)                          { @student_1.roles.first }

    let(:expected_task_types)           { ['homework', 'reading', 'homework', 'external'] }
    let(:expected_tasks)                { expected_task_types.size }

    let(:report)  { reports.first }
    let(:student) { report.students.first }

    it 'has the proper structure' do
      expect(reports.size).to eq 1
      expect(report.data_headings.size).to eq expected_tasks

      data_heading_types = report.data_headings.map(&:type)
      expect(data_heading_types).to eq expected_task_types

      expect(report.students.size).to eq 1

      student_identifiers = report.students.map(&:student_identifier)
      expect(student.student_identifier).to eq 'S1'

      expect(student.data.size).to eq expected_tasks
      data_types = student.data.map(&:type)
      expect(data_types).to eq expected_task_types
    end

    context 'immediate feedback' do
      before do
        Tasks::Models::GradingTemplate.find_each do |grading_template|
          grading_template.update_columns(
            auto_grading_feedback_on: :answer,
            manual_grading_feedback_on: :grade,
            late_work_penalty: 0.0
          )
        end
        Tasks::Models::Task.preload(task_steps: :tasked).find_each do |task|
          task.update_cached_attributes.save validate: false
        end
      end

      it 'returns the proper numbers' do
        hw_score = (1.0 + 0.75)/2
        expect(report.overall_homework_score).to be_within(1e-6).of(hw_score)
        expect(report.overall_homework_progress).to eq 1.0
        rd_score = 0.9
        expect(report.overall_reading_score).to be_within(1e-6).of(rd_score)
        expect(report.overall_reading_progress).to eq 1.0
        expect(report.overall_course_average).to eq(
          (hw_score * course.homework_weight) + (rd_score * course.reading_weight)
        )

        expect(report.data_headings[0].title).to eq 'Homework 2 task plan'
        expect(report.data_headings[0].plan_id).to be_a Integer
        expect(report.data_headings[0].type).to eq 'homework'
        expect(report.data_headings[0].due_at).to be_a Time
        expect(report.data_headings[0].average_score).to eq 0.75
        expect(report.data_headings[0].average_progress).to eq 1.0

        expect(report.data_headings[1].title).to eq 'Reading task plan'
        expect(report.data_headings[1].plan_id).to be_a Integer
        expect(report.data_headings[1].type).to eq 'reading'
        expect(report.data_headings[1].due_at).to be_a Time
        expect(report.data_headings[1].average_score).to be_within(1e-6).of(0.9)
        expect(report.data_headings[1].average_progress).to eq 1.0

        expect(report.data_headings[2].title).to eq 'Homework task plan'
        expect(report.data_headings[2].plan_id).to be_a Integer
        expect(report.data_headings[2].type).to eq 'homework'
        expect(report.data_headings[2].due_at).to be_a Time
        expect(report.data_headings[2].average_score).to eq 1.0
        expect(report.data_headings[2].average_progress).to eq 1.0

        expect(report.data_headings[3].title).to eq 'External assignment'
        expect(report.data_headings[3].plan_id).to be_a Integer
        expect(report.data_headings[3].type).to eq 'external'
        expect(report.data_headings[3].due_at).to be_a Time
        expect(report.data_headings[3].average_score).to be_nil
        expect(report.data_headings[3].average_progress).to eq 0.0

        expect(student.name).to eq @student_1.name
        expect(student.first_name).to eq @student_1.first_name
        expect(student.last_name).to eq @student_1.last_name
        expect(student.role).to eq @student_1.roles.first.id
        expect(student.student_identifier).to(
          eq @student_1.roles.first.student.student_identifier
        )
        expect(student.homework_score).to be_within(1e-6).of((1.0 + 0.75)/2)
        expect(student.homework_progress).to eq 1.0
        expect(student.reading_score).to be_within(1e-6).of(0.9)
        expect(student.reading_progress).to eq 1.0
        expect(student.course_average).to eq(
          (student.homework_score * course.homework_weight) + (student.reading_score * course.reading_weight)
        )

        expect(student.is_dropped).to eq false

        data = student.data
        expect(data.size).to eq expected_tasks
        expect(data.map(&:type)).to eq expected_task_types

        data.each do |data|
          expect(data.id).to be_a Integer
          expect(data.status).to be_in ['completed', 'in_progress', 'not_started']
          expect(data.due_at).to be_a Time
          expect(data.step_count).to be_a Integer
          expect(data.completed_step_count).to be_a Integer
          expect(data.progress).to be_a Float
          # Some assignments might not have feedback available
          # so they might get a nil here even though points/score have been assigned
          expect(data.published_points.class).to be_in([NilClass, Float])
          expect(data.published_score.class).to be_in([NilClass, Float])
        end
      end

      it 'ignores the weights when calculating averages if one assignment type is missing' do
        current_time = Time.current
        Tasks::Models::Task.where(task_type: 'homework').update_all(
          due_at_ntz: current_time + 1.day, closes_at_ntz: current_time + 2.days
        )
        expect(report.overall_homework_score).to be_nil
        expect(report.overall_homework_progress).to be_nil
        rd_score = 0.9
        expect(report.overall_reading_score).to be_within(1e-6).of(rd_score)
        expect(report.overall_reading_progress).to eq 1.0
        expect(report.overall_course_average).to eq rd_score

        expect(report.data_headings[0].title).to eq 'Reading task plan'
        expect(report.data_headings[0].plan_id).to be_a Integer
        expect(report.data_headings[0].type).to eq 'reading'
        expect(report.data_headings[0].due_at).to be_a Time
        expect(report.data_headings[0].average_score).to be_within(1e-6).of(0.9)
        expect(report.data_headings[0].average_progress).to eq 1.0

        expect(report.data_headings[1].title).to eq 'External assignment'
        expect(report.data_headings[1].plan_id).to be_a Integer
        expect(report.data_headings[1].type).to eq 'external'
        expect(report.data_headings[1].due_at).to be_a Time
        expect(report.data_headings[1].average_score).to be_nil
        expect(report.data_headings[1].average_progress).to eq 0.0

        expect(student.name).to eq @student_1.name
        expect(student.first_name).to eq @student_1.first_name
        expect(student.last_name).to eq @student_1.last_name
        expect(student.role).to eq @student_1.roles.first.id
        expect(student.student_identifier).to(
          eq @student_1.roles.first.student.student_identifier
        )
        expect(student.homework_score).to be_nil
        expect(student.homework_progress).to be_nil
        expect(student.reading_score).to be_within(1e-6).of(0.9)
        expect(student.reading_progress).to eq 1.0
        expect(student.course_average).to eq(student.reading_score)

        expect(student.is_dropped).to eq false

        data = student.data
        expect(data.size).to eq 2
        expect(data.map(&:type)).to eq [ 'reading', 'external' ]

        data.each do |data|
          expect(data.id).to be_a Integer
          expect(data.status).to be_in ['completed', 'in_progress', 'not_started']
          expect(data.due_at).to be_a Time
          expect(data.step_count).to be_a Integer
          expect(data.completed_step_count).to be_a Integer
          expect(data.progress).to be_a Float
          # Some assignments might not have feedback available
          # so they might get a nil here even though points/score have been assigned
          expect(data.published_points.class).to be_in([NilClass, Float])
          expect(data.published_score.class).to be_in([NilClass, Float])
        end
      end
    end

    context 'feedback on due date' do
      before do
        Tasks::Models::GradingTemplate.find_each do |grading_template|
          grading_template.update_columns(
            auto_grading_feedback_on: :publish,
            manual_grading_feedback_on: :publish,
            late_work_penalty: 0.0
          )
        end
        Tasks::Models::Task.preload(task_steps: :tasked).find_each do |task|
          task.update_cached_attributes.save validate: false
        end
      end

      it 'does not include correctness and score for tasks with no feedback available' do
        expect(report.data_headings.size).to eq expected_tasks

        expect(report.overall_homework_score).to be_nil
        expect(report.overall_homework_progress).to eq 1.0
        expect(report.overall_reading_score).to be_nil
        expect(report.overall_reading_progress).to eq 1.0
        expect(report.overall_course_average).to be_nil

        expect(report.data_headings[0].title).to eq 'Homework 2 task plan'
        expect(report.data_headings[0].plan_id).to be_a Integer
        expect(report.data_headings[0].type).to eq 'homework'
        expect(report.data_headings[0].due_at).to be_a Time
        expect(report.data_headings[0].average_score).to be_nil
        expect(report.data_headings[0].average_progress).to eq 1.0

        expect(report.data_headings[1].title).to eq 'Reading task plan'
        expect(report.data_headings[1].plan_id).to be_a Integer
        expect(report.data_headings[1].type).to eq 'reading'
        expect(report.data_headings[1].due_at).to be_a Time
        expect(report.data_headings[1].average_score).to be_nil
        expect(report.data_headings[1].average_progress).to eq 1.0

        expect(report.data_headings[2].title).to eq 'Homework task plan'
        expect(report.data_headings[2].plan_id).to be_a Integer
        expect(report.data_headings[2].type).to eq 'homework'
        expect(report.data_headings[2].due_at).to be_a Time
        expect(report.data_headings[2].average_score).to be_nil
        expect(report.data_headings[2].average_progress).to eq 1.0

        expect(report.data_headings[3].title).to eq 'External assignment'
        expect(report.data_headings[3].plan_id).to be_a Integer
        expect(report.data_headings[3].type).to eq 'external'
        expect(report.data_headings[3].due_at).to be_a Time
        expect(report.data_headings[3].average_score).to be_nil
        expect(report.data_headings[3].average_progress).to eq 0.0

        expect(student.name).to eq @student_1.name
        expect(student.first_name).to eq @student_1.first_name
        expect(student.last_name).to eq @student_1.last_name
        expect(student.role).to eq @student_1.roles.first.id
        expect(student.student_identifier).to(
          eq @student_1.roles.first.student.student_identifier
        )
        expect(student.homework_score).to be_nil
        expect(student.homework_progress).to eq 1.0
        expect(student.reading_score).to be_nil
        expect(student.reading_progress).to eq 1.0
        expect(student.course_average).to be_nil

        expect(student.is_dropped).to eq false

        data = student.data
        expect(data.size).to eq expected_tasks
        expect(data.map(&:type)).to eq expected_task_types

        data.each do |data|
          expect(data.id).to be_a Integer
          expect(data.status).to be_in ['completed', 'in_progress', 'not_started']
          expect(data.due_at).to be_a Time
          expect(data.step_count).to be_a Integer
          expect(data.completed_step_count).to be_a Integer
          expect(data.progress).to be_a Float
          # Some assignments might not have feedback available
          # so they might get a nil here even though points/score have been assigned
          expect(data.published_points.class).to be_in([NilClass, Float])
          expect(data.published_score.class).to be_in([NilClass, Float])
        end
      end
    end
  end

  context 'teacher student' do
    let(:role)                { @teacher_student.roles.first }
    let(:expected_task_types) { ['homework', 'reading', 'homework', 'external'] }
    let(:expected_tasks)      { expected_task_types.size }
    let(:report)              { reports.first }
    let(:student)             { report.students.first }

    it 'has the proper structure' do
      expect(reports.size).to eq 1
      expect(report.data_headings.size).to eq expected_tasks
      data_heading_types = report.data_headings.map(&:type)
      expect(data_heading_types).to eq expected_task_types

      expect(report.students.size).to eq 1

      expect(report.students.map(&:student_identifier)).to eq ['']

      expect(student.data.size).to eq expected_tasks
      data_types = student.data.map(&:type)
      expect(data_types).to eq expected_task_types
    end
  end

  context 'random role' do
    let(:role) { FactoryBot.create :entity_role }

    it 'raises SecurityTransgression' do
      expect { reports }.to raise_error(SecurityTransgression)
    end
  end
end
