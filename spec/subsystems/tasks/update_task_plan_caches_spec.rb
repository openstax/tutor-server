require 'rails_helper'

RSpec.describe Tasks::UpdateTaskPlanCaches, type: :routine, speed: :medium do
  let(:course)                  { @task_plan.course }
  let(:periods)                 { course.periods.to_a }
  let(:period_ids)              { periods.map(&:id) }
  let(:first_period)            { periods.first }
  let(:first_task)              do
    @task_plan.tasks.find do |task|
      task.taskings.any? { |tasking| tasking.role.student&.period == first_period }
    end
  end
  let(:num_period_caches)       { periods.size }
  let(:ecosystem)               { course.ecosystem }
  let(:task_plan_ids)           { [ @task_plan.id ] }

  context 'reading' do
    before(:all)                do
      DatabaseCleaner.start

      @task_plan = FactoryBot.create :tasked_task_plan
      withdrawn = FactoryBot.create :tasked_task_plan
      withdrawn.destroy!
    end
    before                      { @task_plan.reload }
    after(:all)                 { DatabaseCleaner.clean }

    context 'with mock ConfiguredJob' do
      let(:configured_job) { Lev::ActiveJob::ConfiguredJob.new(described_class, queue: queue) }

      before do
        allow(described_class).to receive(:set) do |options|
          expect(options[:queue]).to eq queue
          configured_job
        end
      end

      context 'preview' do
        before do
          course.update_attribute :is_preview, true
          @task_plan.update_attribute :is_preview, true
        end

        let(:queue) { :preview }

        it 'calls update_gradable_step_counts for the given task_plans' do
          task_plans = Tasks::Models::TaskPlan.where(id: task_plan_ids)
          expect(Tasks::Models::TaskPlan).to(
            receive(:where).with(id: task_plan_ids).and_return(task_plans)
          )
          expect(task_plans).to receive(:lock).and_return(task_plans)
          expect(task_plans).to receive(:preload).and_return(task_plans)
          task_plans.each do |task_plan|
            expect(task_plan).to receive(:update_gradable_step_counts).and_return(task_plan)
          end

          described_class.call(task_plan_ids: task_plan_ids, queue: queue.to_s)
        end

        it 'is called when a student is dropped' do
          student = first_period.students.first

          expect(configured_job).to receive(:perform_later).with(task_plan_ids: task_plan_ids)

          CourseMembership::InactivateStudent.call(student: student)
        end

        it 'is called when a student is reactivated' do
          student = first_period.students.first
          CourseMembership::InactivateStudent.call(student: student)

          expect(ReassignPublishedPeriodTaskPlans).to receive(:[])

          expect(configured_job).to receive(:perform_later).with(task_plan_ids: task_plan_ids)

          CourseMembership::ActivateStudent.call(student: student)
        end
      end

      context 'not preview' do
        let(:queue) { :dashboard }

        it 'calls update_gradable_step_counts for the given task_plans' do
          task_plans = Tasks::Models::TaskPlan.where(id: task_plan_ids)
          expect(Tasks::Models::TaskPlan).to(
            receive(:where).with(id: task_plan_ids).and_return(task_plans)
          )
          expect(task_plans).to receive(:lock).and_return(task_plans)
          expect(task_plans).to receive(:preload).and_return(task_plans)
          task_plans.each do |task_plan|
            expect(task_plan).to receive(:update_gradable_step_counts).and_return(task_plan)
          end

          described_class.call(task_plan_ids: task_plan_ids, queue: queue.to_s)
        end

        it 'is called when a student is dropped' do
          student = first_period.students.first

          expect(configured_job).to receive(:perform_later).with(task_plan_ids: task_plan_ids)

          CourseMembership::InactivateStudent.call(student: student)
        end

        it 'is called when a student is reactivated' do
          student = first_period.students.first
          CourseMembership::InactivateStudent.call(student: student)

          expect(ReassignPublishedPeriodTaskPlans).to receive(:[])

          expect(configured_job).to receive(:perform_later).with(task_plan_ids: task_plan_ids)

          CourseMembership::ActivateStudent.call(student: student)
        end
      end
    end
  end

  context 'external' do
    before(:all)                do
      DatabaseCleaner.start

      assistant = Tasks::Models::Assistant.find_by(
        code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant'
      ) || FactoryBot.create(
        :tasks_assistant, code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant'
      )

      @task_plan = FactoryBot.create(
        :tasked_task_plan,
        type: 'external',
        assistant: assistant,
        settings: { external_url: 'https://www.example.com' }
      )

      withdrawn = FactoryBot.create(
        :tasked_task_plan,
        type: 'external',
        assistant: assistant,
        settings: { external_url: 'https://not.here' }
      )
      withdrawn.destroy!
    end
    before                      { @task_plan.reload }
    after(:all)                 { DatabaseCleaner.clean }

    let(:queue)                 { :dashboard }

    it 'works' do
      described_class.call(task_plan_ids: task_plan_ids, queue: queue.to_s)
    end
  end
end
