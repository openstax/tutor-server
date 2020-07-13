require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::FreezeEndedCourseTeacherPerformanceReports, type: :routine do
  before(:all) do
    VCR.use_cassette("Tasks_GetPerformanceReport/with_book", VCR_OPTS) do
      @ecosystem = FetchAndImportBookAndCreateEcosystem[
        book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
      ]
    end
    @course = FactoryBot.create(
      :course_profile_course, :with_assistants, :with_grading_templates,
                              reading_weight: 0, homework_weight: 1
    )
    CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)

    @teacher = FactoryBot.create(:user_profile)
    @student_1 = FactoryBot.create(:user_profile)
    @student_2 = FactoryBot.create(:user_profile)
    @student_3 = FactoryBot.create(:user_profile)
    @student_4 = FactoryBot.create(:user_profile)

    @teacher_student = FactoryBot.create(:user_profile)

    SetupPerformanceReportData[
      course: @course,
      teacher: @teacher,
      students: [@student_1, @student_2, @student_3, @student_4],
      teacher_students: [@teacher_student],
      ecosystem: @ecosystem
    ]

    # External assignment
    external_assistant = @course.course_assistants
                                .find_by(tasks_task_plan_type: 'external')
                                .assistant

    external_task_plan = FactoryBot.build(
      :tasks_task_plan,
      title: 'External assignment',
      course: @course,
      type: 'external',
      assistant: external_assistant,
      content_ecosystem_id: @ecosystem.id,
      settings: { external_url: 'https://www.example.com' },
      num_tasking_plans: 0
    )

    external_task_plan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: @course,
      task_plan: external_task_plan,
      opens_at: @course.time_zone.now - 5.weeks,
      due_at: @course.time_zone.now - 4.weeks,
      closes_at: @course.time_zone.now - 3.weeks
    )

    external_task_plan.save!

    DistributeTasks.call(task_plan: external_task_plan)

    # Event
    event_assistant = @course.course_assistants
                             .find_by(tasks_task_plan_type: 'event')
                             .assistant

    event_task_plan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Event',
      course: @course,
      type: 'event',
      assistant: event_assistant,
      content_ecosystem_id: @ecosystem.id,
      num_tasking_plans: 0
    )

    event_task_plan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: @course,
      task_plan: event_task_plan,
      opens_at: @course.time_zone.now - 2.weeks,
      due_at: @course.time_zone.now - 1.week,
      closes_at: @course.time_zone.now
    )

    event_task_plan.save!

    DistributeTasks.call(task_plan: event_task_plan)

    # Draft assignment, not included in the scores
    reading_assistant = @course.course_assistants
                               .find_by(tasks_task_plan_type: 'reading')
                               .assistant

    draft_task_plan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Draft task plan',
      course: @course,
      type: 'reading',
      assistant: reading_assistant,
      content_ecosystem_id: @ecosystem.id,
      settings: { page_ids: @ecosystem.pages.first(2).map(&:id).map(&:to_s) },
      num_tasking_plans: 0
    )

    draft_task_plan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: @course,
      task_plan: draft_task_plan,
      opens_at: @course.time_zone.now - 1.week,
      due_at: @course.time_zone.now,
      closes_at: @course.time_zone.now + 1.week
    )

    draft_task_plan.save!

    # Create the preview task, which might interfere with the scores
    DistributeTasks.call(task_plan: draft_task_plan, preview: true)
  end

  before { @course.reload }

  context 'course has not ended yet' do
    it 'does nothing' do
      expect(Tasks::ExportPerformanceReport).not_to receive(:call)

      expect do
        described_class.call
      end.to  not_change { @course.reload.frozen_scores? }.from(false)
         .and not_change { @course.teacher_performance_report }.from(nil)

      expect(@course.teacher_performance_report).to be_nil
    end
  end

  context 'course has ended' do
    before { @course.update_attribute :ends_at, Time.current }

    it "freezes the course's teacher performance report" do
      reports = Tasks::GetPerformanceReport[course: @course, is_teacher: true]

      expect(Tasks::ExportPerformanceReport).to receive(:call).and_call_original

      expect do
        described_class.call
      end.to  change { @course.reload.frozen_scores? }.from(false).to(true)
         .and change { @course.teacher_performance_report }.from(nil)

      # Some objects like AR models don't serialize/deserialize entirely the same,
      # so we save the representation instead.
      # The overall representation should always match
      expect(
        Api::V1::PerformanceReport::Representer.new(
          Tasks::GetPerformanceReport[course: @course, is_teacher: true]
        ).to_hash
      ).to eq Api::V1::PerformanceReport::Representer.new(reports).to_hash
    end
  end
end
