require 'rails_helper'
require 'fork_with_connection'

RSpec.describe DistributeTasks, type: :routine, truncation: true do

  let(:course)    { FactoryGirl.create :course_profile_course }
  let(:period)    { FactoryGirl.create :course_membership_period, course: course }
  let!(:user)     do
    FactoryGirl.create(:user).tap do |user|
      AddUserAsPeriodStudent.call(user: user, period: period)
    end
  end
  let!(:new_user) do
    FactoryGirl.create(:user).tap do |user|
      AddUserAsPeriodStudent.call(user: user, period: period)
    end
  end
  let(:task_plan) do
    task_plan = FactoryGirl.build(:tasks_task_plan, owner: course)
    task_plan.tasking_plans.first.target = period.to_model
    task_plan.save!
    task_plan
  end

  context 'a homework' do
    let(:assistant)     do
      FactoryGirl.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant')
    end
    let(:homework_plan) do
      task_plan = FactoryGirl.build(
        :tasks_task_plan,
        assistant: assistant,
        owner: course,
        type: 'homework',
        ecosystem: @ecosystem.to_model,
        settings: { exercise_ids: exercise_ids[0..5], exercises_count_dynamic: 3}
      )
      task_plan.tasking_plans.first.target = period.to_model
      task_plan.save!
      task_plan
    end
    let(:core_pools)   { @ecosystem.homework_core_pools(pages: @pages) }
    let(:exercise_ids) { core_pools.flat_map(&:exercises).map{|e| e.id.to_s} }

    before do
      allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
        receive(:k_ago_map) { [ [2, 4] ] }
      )
      allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
        receive(:num_personalized_exercises) { 3 }
      )
      generate_test_exercise_content
    end

    it 'creates a preview and distributes the steps' do
      step_types = ["core_group", "core_group", "core_group", "core_group", "core_group",
                    "core_group", "personalized_group", "personalized_group", "personalized_group"]

      results = DistributeTasks.call(task_plan: homework_plan, preview: true)
      expect(results.errors).to be_empty

      expect(homework_plan.reload.tasks.length).to eq 1

      homework_plan.tasks.each do | task |
        expect(task.task_steps.map(&:group_type)).to eq(step_types)
      end

      results = DistributeTasks.call(task_plan: homework_plan)
      expect(results.errors).to be_empty

      expect(homework_plan.reload.tasks.length).to eq 3

      homework_plan.tasks.each do | task |
        expect(task.task_steps.map(&:group_type)).to eq(step_types)
      end
    end

    # Note - this isn't 100% guaranteed to fail.  There's still a chance that the forked children will process
    # distribution in a way that doesn't trigger IsolationConflict exceptions.
    # If this spec starts to fail in indeterminate ways and can't be fixed it can be removed
    it 'cannot be distributed concurrently' do
      plan = homework_plan
      pids = []
      0.upto(5) do
        pids << Tutor.fork_with_connection do
          begin
            DistributeTasks.call(task_plan: plan)
            0 # all we care about for this spec is isolation conflicts, anything else is considered passing
          rescue ActiveRecord::TransactionIsolationConflict
            99 # arbitrary exit status to indicate failure
          end
        end
      end
      failed = []
      pids.each do |pid|
        Process.wait(pid)
        failed << pid if $?.exitstatus == 99
      end
      expect(failed).not_to be_empty
    end
  end

  context 'unpublished task_plan' do
    context 'before the open date' do
      before(:each) do
        opens_at = Time.current.tomorrow
        task_plan.tasking_plans.each{ |tp| tp.update_attribute(:opens_at, opens_at) }
        task_plan.tasks.each{ |task| task.update_attribute(:opens_at, opens_at) }
      end

      context 'creating a preview task' do
        it 'can create a preview' do
          expect(task_plan.tasks).to be_empty
          result = DistributeTasks.call(task_plan: task_plan, preview: true)

          expect(result.errors).to be_empty
          expect(task_plan.reload.tasks.size).to eq 1
          expect(task_plan.tasks.first.taskings.first.role).to eq period.teacher_student_role
          expect(task_plan).not_to be_out_to_students
        end

        it 'does not save plan if it is new' do
          new_plan = task_plan.dup
          result = DistributeTasks.call(task_plan: new_plan, preview: true)
          expect(result.errors).to be_empty
          expect(new_plan).to be_new_record
        end
      end

      it 'creates tasks for the task_plan' do
        expect(task_plan.tasks).to be_empty
        result = DistributeTasks.call(task_plan: task_plan)
        expect(result.errors).to be_empty
        expect(task_plan.reload.tasks.size).to eq 3
      end

      it 'sets the published_at fields' do
        result = DistributeTasks.call(task_plan: task_plan)
        expect(result.errors).to be_empty
        task_plan.reload
        expect(task_plan.first_published_at).to be_within(1).of(Time.current)
        expect(task_plan.last_published_at).to be_within(1).of(Time.current)
      end

      it 'fails to publish the task_plan if one or more non-stepless tasks would be empty' do
        original_build_tasks = DummyAssistant.instance_method(:build_tasks)
        allow_any_instance_of(DummyAssistant).to receive(:build_tasks) do |receiver|
          tasks = original_build_tasks.bind(receiver).call
          tasks.each{ |task| task.task_type = :reading }
        end

        expect(task_plan.tasks).to be_empty
        result = DistributeTasks.call(task_plan: task_plan)
        expect(result.errors.first.code).to eq :empty_tasks
        expect(task_plan.tasks).to be_empty
      end
    end

    context 'after the open date' do
      before(:each) do
        opens_at = Time.current.yesterday
        task_plan.tasking_plans.each{ |tp| tp.update_attribute(:opens_at, opens_at) }
        task_plan.tasks.each{ |task| task.update_attribute(:opens_at, opens_at) }
      end

      it 'creates tasks for the task_plan' do
        expect(task_plan.tasks).to be_empty
        result = DistributeTasks.call(task_plan: task_plan)
        expect(result.errors).to be_empty
        expect(task_plan.reload.tasks.size).to eq 3
      end

      it 'sets the published_at fields' do
        result = DistributeTasks.call(task_plan: task_plan)
        expect(result.errors).to be_empty
        task_plan.reload
        expect(task_plan.first_published_at).to be_within(1).of(Time.current)
        expect(task_plan.last_published_at).to be_within(1).of(Time.current)
      end

      it 'fails to publish the task_plan if one or more non-stepless tasks would be empty' do
        original_build_tasks = DummyAssistant.instance_method(:build_tasks)
        allow_any_instance_of(DummyAssistant).to receive(:build_tasks) do |receiver|
          tasks = original_build_tasks.bind(receiver).call
          tasks.each{ |task| task.task_type = :reading }
        end

        expect(task_plan.tasks).to be_empty
        result = DistributeTasks.call(task_plan: task_plan)
        expect(result.errors.first.code).to eq :empty_tasks
        expect(task_plan.tasks).to be_empty
      end
    end
  end

  context 'published task_plan' do
    before(:each) do
      DistributeTasks.call(task_plan: task_plan)
      new_user.to_model.roles.each do |role|
        role.taskings.each{ |tasking| tasking.task.really_destroy! }
      end
      task_plan.reload
    end

    context 'before the open date' do
      before(:each) do
        opens_at = Time.current.tomorrow
        task_plan.tasking_plans.each{ |tp| tp.update_attribute(:opens_at, opens_at) }
        task_plan.tasks.each{ |task| task.update_attribute(:opens_at, opens_at) }
      end

      it 'rebuilds the tasks for the task_plan' do
        expect(task_plan.tasks.size).to eq 2
        old_task = task_plan.tasks.first

        result = DistributeTasks.call(task_plan: task_plan)
        expect(result.errors).to be_empty
        expect(task_plan.reload.tasks.size).to eq 3
        expect(task_plan.tasks).not_to include old_task
      end

      it 'does not set the first_published_at field' do
        old_published_at = task_plan.first_published_at
        publish_time = Time.current
        result = DistributeTasks.call(task_plan: task_plan, publish_time: publish_time)
        expect(result.errors).to be_empty
        task_plan.reload
        expect(task_plan.first_published_at).to eq old_published_at
        expect(task_plan.last_published_at).to be_within(1e-6).of(publish_time)
      end
    end

    context 'after the open date' do
      before(:each) do
        opens_at = Time.current.yesterday
        task_plan.tasking_plans.each{ |tp| tp.update_attribute(:opens_at, opens_at) }
        task_plan.tasks.each{ |task| task.update_attribute(:opens_at, opens_at) }
      end

      it 'does not rebuild existing tasks for the task_plan' do
        expect(task_plan.tasks.size).to eq 2
        old_task = task_plan.tasks.first

        result = DistributeTasks.call(task_plan: task_plan)
        expect(result.errors).to be_empty
        expect(task_plan.reload.tasks.size).to eq 3
        expect(task_plan.tasks).to include old_task
      end

      it 'does not set the first_published_at field' do
        old_published_at = task_plan.first_published_at
        publish_time = Time.current
        result = DistributeTasks.call(task_plan: task_plan, publish_time: publish_time)
        expect(result.errors).to be_empty
        expect(task_plan.reload.first_published_at).to eq old_published_at
        expect(task_plan.last_published_at).to be_within(1e-6).of(publish_time)
      end
    end
  end
end
