require 'rails_helper'

RSpec.describe Tasks::UpdateTaskCaches, type: :routine, speed: :medium do
  let(:course)                  { @task_plan.course }
  let(:tasks)                   { @task_plan.tasks.to_a }
  let(:task_ids)                { tasks.map(&:id) }

  context 'reading' do
    before(:all)                do
      DatabaseCleaner.start

      @task_plan = FactoryBot.create :tasked_task_plan
    end
    after(:all)                 { DatabaseCleaner.clean }

    before do
      @task_plan.reload

      allow(described_class).to receive(:set) do |options|
        expect(options[:queue]).to eq queue
        configured_job
      end
    end

    let(:configured_job)        { Lev::ActiveJob::ConfiguredJob.new(described_class, queue: queue) }

    context 'preview' do
      before do
        course.update_attribute :is_preview, true
        @task_plan.update_attribute :is_preview, true
      end

      let(:queue) { :preview }

      it 'calls update_cached_attributes for the given tasks' do
        tasks = Tasks::Models::Task.where(id: task_ids)
        expect(Tasks::Models::Task).to receive(:where).with(id: task_ids).and_return(tasks)
        expect(tasks).to receive(:lock).and_return(tasks)
        expect(tasks).to receive(:preload).and_return(tasks)
        tasks.each { |task| expect(task).to receive(:update_cached_attributes).and_return(task) }

        expect(Tasks::UpdateTaskPlanCaches).to receive(:call)

        described_class.call(task_ids: task_ids, queue: queue.to_s)
      end

      it 'is called when a task_plan is published' do
        @task_plan.tasks.delete_all

        expect(configured_job).to(
          receive(:perform_later) do |task_ids:, queue:|
            expect(task_ids).to match_array(@task_plan.tasks.reset.pluck(:id))
            expect(queue).to eq queue.to_s
          end
        )

        DistributeTasks.call(task_plan: @task_plan)
      end

      it 'is called when a task step is updated' do
        task = @task_plan.tasks.first
        expect(configured_job).to receive(:perform_later).with(task_ids: task.id, queue: queue.to_s)

        tasked_exercise = task.tasked_exercises.first
        tasked_exercise.free_response = 'Something'
        tasked_exercise.save!
      end

      it 'is called when a task step is marked as completed' do
        task = @task_plan.tasks.first
        expect(configured_job).to receive(:perform_later).with(task_ids: task.id, queue: queue.to_s)

        task_step = task.task_steps.first
        MarkTaskStepCompleted.call(task_step: task_step)
      end

      it 'is called when placeholder steps are populated' do
        task = @task_plan.tasks.first
        expect(described_class).to receive(:call).once.with(tasks: task, queue: queue.to_s)

        Tasks::PopulatePlaceholderSteps.call(task: task)
      end

      it 'is called when a new ecosystem is added to the course' do
        ecosystem = course.ecosystem
        course.course_ecosystems.delete_all :delete_all

        expect(configured_job).to(
          receive(:perform_later) do |task_ids:, queue:|
            student_task_ids = @task_plan.tasks.filter do |task|
              task.taskings.any? { |tasking| tasking.role.student.present? }
            end.map(&:id)
            expect(task_ids).to match_array(student_task_ids)
            expect(queue).to eq queue.to_s
          end
        )

        AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
      end

      it 'is called when a new student joins the course' do
        student_user = FactoryBot.create :user_profile
        period = course.periods.first
        existing_task_ids = tasks.map(&:id)
        expect(configured_job).to(
          receive(:perform_later) do |task_ids:, queue:|
            expect(task_ids.size).to eq 11
            expect(queue).to eq queue.to_s
            expect((task_ids - existing_task_ids).size).to eq 1
          end
        )

        AddUserAsPeriodStudent.call(user: student_user, period: period)
      end
    end

    context 'not preview' do
      let(:queue) { :dashboard }

      it 'calls update_cached_attributes for the given tasks' do
        tasks = Tasks::Models::Task.where(id: task_ids)
        expect(Tasks::Models::Task).to receive(:where).with(id: task_ids).and_return(tasks)
        expect(tasks).to receive(:lock).and_return(tasks)
        expect(tasks).to receive(:preload).and_return(tasks)
        tasks.each { |task| expect(task).to receive(:update_cached_attributes).and_return(task) }

        expect(Tasks::UpdateTaskPlanCaches).to receive(:call)

        described_class.call(task_ids: task_ids, queue: queue.to_s)
      end

      it 'is called when a task_plan is published' do
        @task_plan.tasks.delete_all

        expect(configured_job).to(
          receive(:perform_later) do |task_ids:, queue:|
            expect(task_ids).to match_array(@task_plan.tasks.reset.pluck(:id))
            expect(queue).to eq queue.to_s
          end
        )

        DistributeTasks.call(task_plan: @task_plan)
      end

      it 'is called when a task step is updated' do
        task = @task_plan.tasks.first
        expect(configured_job).to receive(:perform_later).with(task_ids: task.id, queue: queue.to_s)

        tasked_exercise = task.tasked_exercises.first
        tasked_exercise.free_response = 'Something'
        tasked_exercise.save!
      end

      it 'is called when a task step is marked as completed' do
        task = @task_plan.tasks.first
        expect(configured_job).to(
          receive(:perform_later).with(task_ids: task.id, queue: queue.to_s)
        )

        task_step = task.task_steps.first
        MarkTaskStepCompleted.call(task_step: task_step)
      end

      it 'is called when placeholder steps are populated' do
        task = @task_plan.tasks.first
        expect(described_class).to receive(:call).once.with(tasks: task, queue: queue.to_s)

        Tasks::PopulatePlaceholderSteps.call(task: task)
      end

      it 'is called when a new ecosystem is added to the course' do
        ecosystem = course.ecosystem
        course.course_ecosystems.delete_all :delete_all

        expect(configured_job).to(
          receive(:perform_later) do |task_ids:, queue:|
            student_task_ids = @task_plan.tasks.filter do |task|
              task.taskings.any? { |tasking| tasking.role.student.present? }
            end.map(&:id)
            expect(task_ids).to match_array(student_task_ids)
            expect(queue).to eq queue.to_s
          end
        )

        AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
      end

      it 'is called when a new student joins the course' do
        student_user = FactoryBot.create :user_profile
        period = course.periods.first
        existing_task_ids = tasks.map(&:id)
        expect(configured_job).to(
          receive(:perform_later) do |task_ids:, queue:|
            expect(task_ids.size).to eq 11
            expect(queue).to eq queue.to_s
            expect((task_ids - existing_task_ids).size).to eq 1
          end
        )

        AddUserAsPeriodStudent.call(user: student_user, period: period)
      end

      it "requeues itself if run_at_due and the task's due_at changed" do
        task = tasks.first
        task.update_attribute :due_at, Time.current + 1.month

        expect do
          Delayed::Worker.with_delay_jobs(true) do
            described_class.call task_ids: task.id, run_at_due: true
          end
        end.to  change { Delayed::Job.count }.by(1)
           .and change { task.reload.task_cache_job_id }
      end
    end
  end

  context 'external' do
    before(:all)                do
      DatabaseCleaner.start

      @task_plan = FactoryBot.create(
        :tasked_task_plan,
        type: 'external',
        assistant: Tasks::Models::Assistant.find_by(
          code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant'
        ) || FactoryBot.create(
          :tasks_assistant, code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant'
        ),
        settings: { external_url: 'https://www.example.com' }
      )
    end
    after(:all)                 { DatabaseCleaner.clean }

    before                      { @task_plan.reload }

    let(:queue)                 { :dashboard }

    it 'works' do
      described_class.call task_ids: task_ids
    end
  end
end
