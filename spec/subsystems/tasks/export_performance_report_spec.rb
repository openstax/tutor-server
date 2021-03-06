require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::ExportPerformanceReport, type: :routine do
  before(:all) do
    @ecosystem = FactoryBot.create :mini_ecosystem

    @course = FactoryBot.create :course_profile_course, :with_assistants
    CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)

    @teacher = FactoryBot.create(:user_profile)
    SetupPerformanceReportData[course: @course, teacher: @teacher, ecosystem: @ecosystem]

    reading_assistant = @course.course_assistants
                               .find_by(tasks_task_plan_type: 'reading')
                               .assistant

    # Draft assignment, not included in the scores
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

    @role = GetUserCourseRoles[courses: @course, user: @teacher].first
  end

  before { @course.reload }

  context 'new scores' do
    before do
      expect(Tasks::PerformanceReport::ExportXlsx).to(
        receive(:call).and_wrap_original do |method, **args|
          expect(args[:course]).to eq @course
          args[:report].each { |report| expect(report.data_headings.size).to eq 3 }
          method.call(args)
        end
      )
    end
    after do
      File.delete(@output_filename) if !@output_filename.nil? && File.exist?(@output_filename)
    end

    context 'uncached' do
      it 'does not blow up' do
        expect do
          @output_filename = described_class[role: @role, course: @course]
        end.not_to raise_error
      end

      it 'does not blow up when a student was not assigned a particular task' do
        @course.students.first.role.taskings.first.task.destroy
        expect do
          @output_filename = described_class[role: @role, course: @course]
        end.not_to raise_error
      end

      it 'does not blow up if the course name has forbidden characters' do
        @course.update_attribute(:name, "My/\\C00l\r\n\tC0ur$3 :-)")
        expect do
          @output_filename = described_class[role: @role, course: @course]
        end.not_to raise_error
      end

      it 'does not blow up if the course name is too long' do
        @course.update_attribute(:name, 'Tro' + (['lo'] * 50).join)
        expect do
          @output_filename = described_class[role: @role, course: @course]
        end.not_to raise_error
      end
    end

    context 'cached' do
      it 'does not blow up with a cached performance report' do
        FactoryBot.create(
          :course_profile_cache,
          course: @course,
          teacher_performance_report: Api::V1::PerformanceReport::Representer.new(
            Tasks::GetPerformanceReport[role: @role, course: @course]
          ).to_hash
        )
        @course.ends_at = Time.current
        @course.save validate: false

        expect do
          @output_filename = described_class[role: @role, course: @course]
        end.not_to raise_error
      end

      it 'uses the last performance export, if available' do
        @output_filename = described_class[role: @role, course: @course]

        FactoryBot.create(
          :course_profile_cache,
          course: @course,
          teacher_performance_report: Api::V1::PerformanceReport::Representer.new(
            Tasks::GetPerformanceReport[role: @role, course: @course]
          ).to_hash
        )
        @course.ends_at = Time.current
        @course.save validate: false

        expect do
          expect(described_class[role: @role, course: @course]).to eq @output_filename
        end.not_to raise_error
      end
    end
  end

  context 'old scores' do
    before do
      @course.ends_at = DateTime.new 2020, 6, 30
      expect(Tasks::PerformanceReport::ExportPreWrmXlsx).to(
        receive(:call).and_wrap_original do |method, **args|
          expect(args[:course]).to eq @course
          args[:report].each { |report| expect(report.data_headings.size).to eq 3 }
          method.call(args)
        end
      )
    end
    after do
      File.delete(@output_filename) if !@output_filename.nil? && File.exist?(@output_filename)
    end

    context 'uncached' do
      it 'does not blow up' do
        expect do
          @output_filename = described_class[role: @role, course: @course]
        end.not_to raise_error
      end

      it 'does not blow up when a student was not assigned a particular task' do
        @course.students.first.role.taskings.first.task.destroy
        expect do
          @output_filename = described_class[role: @role, course: @course]
        end.not_to raise_error
      end

      it 'does not blow up if the course name has forbidden characters' do
        @course.update_attribute(:name, "My/\\C00l\r\n\tC0ur$3 :-)")
        expect do
          @output_filename = described_class[role: @role, course: @course]
        end.not_to raise_error
      end

      it 'does not blow up if the course name is too long' do
        @course.update_attribute(:name, 'Tro' + (['lo'] * 50).join)
        expect do
          @output_filename = described_class[role: @role, course: @course]
        end.not_to raise_error
      end
    end

    context 'cached' do
      it 'does not blow up with a cached performance report' do
        FactoryBot.create(
          :course_profile_cache,
          course: @course, teacher_performance_report: Api::V1::PerformanceReport::Representer.new(
            Tasks::GetPerformanceReport[role: @role, course: @course]
          ).to_hash
        )

        expect do
          @output_filename = described_class[role: @role, course: @course]
        end.not_to raise_error
      end

      it 'uses the last performance export, if available' do
        @output_filename = described_class[role: @role, course: @course]

        FactoryBot.create(
          :course_profile_cache,
          course: @course, teacher_performance_report: Api::V1::PerformanceReport::Representer.new(
            Tasks::GetPerformanceReport[role: @role, course: @course]
          ).to_hash
        )

        expect do
          expect(described_class[role: @role, course: @course]).to eq @output_filename
        end.not_to raise_error
      end
    end
  end
end
