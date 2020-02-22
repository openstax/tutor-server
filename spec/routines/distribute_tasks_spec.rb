require 'rails_helper'

RSpec.describe DistributeTasks, type: :routine, truncation: true, speed: :medium do
  let(:course)    { FactoryBot.create :course_profile_course }
  let(:period)    { FactoryBot.create :course_membership_period, course: course }
  let!(:user)     do
    FactoryBot.create(:user).tap do |user|
      AddUserAsPeriodStudent.call(user: user, period: period)
    end
  end
  let!(:new_user) do
    FactoryBot.create(:user).tap do |user|
      AddUserAsPeriodStudent.call(user: user, period: period)
    end
  end
  let(:task_plan) do
    FactoryBot.build(:tasks_task_plan, owner: course).tap do |task_plan|
      task_plan.tasking_plans.first.target = period.to_model
      task_plan.save!
    end
  end
  let(:tasking_plan) { task_plan.tasking_plans.first }
  let(:teacher_student_role) do
    FactoryBot.create(:course_membership_teacher_student, period: period).role
  end

  let(:homework_plan) do
    FactoryBot.build(
      :tasks_task_plan,
      assistant: FactoryBot.create(
        :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
      ),
      owner: course,
      type: 'homework',
      ecosystem: @ecosystem.to_model,
      settings: {
        exercises: exercises[0..5].map do |exercise|
          { id: exercise.id.to_s, points: [ 1 ] * exercise.to_model.num_questions }
        end,
        exercises_count_dynamic: 3
      }
    ).tap do |task_plan|
      task_plan.tasking_plans.first.target = period.to_model
      task_plan.save!
    end
  end
  let(:core_pools) { @ecosystem.homework_core_pools(pages: @pages) }
  let(:exercises)  { core_pools.flat_map(&:exercises) }

  context 'with no teacher_student roles' do
    context 'homework' do
      before do
        allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
          receive(:num_spaced_practice_exercises) { 3 }
        )

        generate_homework_test_exercise_content
      end

      it 'distributes the steps' do
        expected_step_types = ['fixed_group'] * 6 + ['spaced_practice_group'] * 3

        results = described_class.call(task_plan: homework_plan, preview: true)
        expect(results.errors).to be_empty

        expect(homework_plan.reload.tasks.length).to eq 0

        results = described_class.call(task_plan: homework_plan)
        expect(results.errors).to be_empty

        expect(homework_plan.reload.tasks.length).to eq 2

        homework_plan.tasks.each do | task |
          expect(task.task_steps.map(&:group_type)).to eq(expected_step_types)
        end
      end
    end
  end

  context 'with a teacher_student role' do
    before { teacher_student_role }

    context 'homework' do
      before do
        allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
          receive(:num_spaced_practice_exercises) { 3 }
        )

        generate_homework_test_exercise_content
      end

      it 'creates a preview and distributes the steps' do
        expected_step_types = ['fixed_group'] * 6 + ['spaced_practice_group'] * 3

        results = described_class.call(task_plan: homework_plan, preview: true)
        expect(results.errors).to be_empty

        expect(homework_plan.reload.tasks.length).to eq 1

        homework_plan.tasks.each do | task |
          expect(task.task_steps.map(&:group_type)).to eq(expected_step_types)
        end

        results = described_class.call(task_plan: homework_plan)
        expect(results.errors).to be_empty

        expect(homework_plan.reload.tasks.length).to eq 3

        homework_plan.tasks.each do | task |
          expect(task.task_steps.map(&:group_type)).to eq(expected_step_types)
        end
      end
    end

    context 'unpublished task_plan' do
      before { expect(task_plan).not_to be_out_to_students }

      context 'before the open date' do
        before do
          opens_at = Time.current.tomorrow
          task_plan.tasking_plans.each { |tp| tp.update_attribute(:opens_at, opens_at) }
          task_plan.tasks.each { |task| task.update_attribute(:opens_at, opens_at) }
        end

        context 'preview' do
          before { teacher_student_role }

          it 'can create or update a preview task' do
            expect(task_plan.tasks).to be_empty
            result = described_class.call(task_plan: task_plan, preview: true)

            expect(result.errors).to be_empty
            expect(task_plan.reload.tasks.size).to eq 1
            expect(task_plan).not_to be_out_to_students
            task = task_plan.tasks.first
            expect(task.taskings.first.role).to eq teacher_student_role
            expect(task.opens_at).to be_within(1e-6).of(tasking_plan.opens_at)

            tasking_plan.update_attribute :opens_at, tasking_plan.time_zone.to_tz.now + 1.hour
            result = described_class.call(task_plan: task_plan, preview: true)

            expect(result.errors).to be_empty
            expect(task_plan.reload.tasks.size).to eq 1
            expect(task_plan).not_to be_out_to_students
            task = task_plan.tasks.first
            expect(task.taskings.first.role).to eq teacher_student_role
            expect(task.opens_at).to be_within(1e-6).of(tasking_plan.opens_at)
          end

          it 'does not save plan if it is new' do
            new_plan = task_plan.dup
            result = described_class.call(task_plan: new_plan, preview: true)
            expect(result.errors).to be_empty
            expect(new_plan).to be_new_record
          end
        end

        it 'can create or update normal and preview tasks' do
          tasking_plan.update_attribute :opens_at, tasking_plan.time_zone.to_tz.now + 1.hour
          result = described_class.call(task_plan: task_plan)

          expect(result.errors).to be_empty
          expect(task_plan.reload.tasks.size).to eq 3
          expect(task_plan).not_to be_out_to_students
          task_plan.tasks.each do |task|
            expect(task.opens_at).to be_within(1e-6).of(tasking_plan.opens_at)
          end
        end

        it 'sets the published_at fields' do
          publish_time = Time.current
          result = described_class.call(task_plan: task_plan, publish_time: publish_time)
          expect(result.errors).to be_empty
          task_plan.reload
          expect(task_plan.first_published_at).to be_within(1).of(publish_time)
          expect(task_plan.last_published_at).to be_within(1).of(publish_time)
        end

        it 'fails to publish the task_plan if one or more non-stepless tasks would be empty' do
          original_build_tasks = DummyAssistant.instance_method(:build_tasks)
          allow_any_instance_of(DummyAssistant).to receive(:build_tasks) do |receiver|
            tasks = original_build_tasks.bind(receiver).call
            tasks.each { |task| task.task_type = :reading }
          end

          expect(task_plan.tasks).to be_empty
          result = described_class.call(task_plan: task_plan)
          expect(result.errors.first.code).to eq :empty_tasks
          expect(task_plan.tasks).to be_empty
        end
      end

      context 'after the open date' do
        before do
          opens_at = Time.current.yesterday
          task_plan.tasking_plans.each { |tp| tp.update_attribute(:opens_at, opens_at) }
          task_plan.tasks.each { |task| task.update_attribute(:opens_at, opens_at) }
        end

        it 'can create or update normal and preview tasks' do
          tasking_plan.update_attribute :opens_at, tasking_plan.time_zone.to_tz.now - 1.hour
          result = described_class.call(task_plan: task_plan)

          expect(result.errors).to be_empty
          expect(task_plan.reload.tasks.size).to eq 3
          expect(task_plan).to be_out_to_students
          task_plan.tasks.each do |task|
            expect(task.opens_at).to be_within(1e-6).of(tasking_plan.opens_at)
          end
        end

        it 'sets the published_at fields' do
          publish_time = Time.current
          result = described_class.call(task_plan: task_plan, publish_time: publish_time)
          expect(result.errors).to be_empty
          task_plan.reload
          expect(task_plan.first_published_at).to be_within(1).of(publish_time)
          expect(task_plan.last_published_at).to be_within(1).of(publish_time)
        end

        it 'fails to publish the task_plan if one or more non-stepless tasks would be empty' do
          original_build_tasks = DummyAssistant.instance_method(:build_tasks)
          allow_any_instance_of(DummyAssistant).to receive(:build_tasks) do |receiver|
            tasks = original_build_tasks.bind(receiver).call
            tasks.each { |task| task.task_type = :reading }
          end

          expect(task_plan.tasks).to be_empty
          result = described_class.call(task_plan: task_plan)
          expect(result.errors.first.code).to eq :empty_tasks
          expect(task_plan.tasks).to be_empty
        end
      end
    end

    context 'published task_plan' do
      before do
        described_class.call(task_plan: task_plan)
        new_user.to_model.roles.each do |role|
          role.taskings.each { |tasking| tasking.task.really_destroy! }
        end
        expect(task_plan.reload).to be_out_to_students
      end

      context 'before the open date' do
        before do
          opens_at = Time.current.tomorrow
          task_plan.tasking_plans.each { |tp| tp.update_attribute(:opens_at, opens_at) }
          task_plan.tasks.each { |task| task.update_attribute(:opens_at, opens_at) }
        end

        it 'can create or update normal and preview tasks' do
          tasking_plan.update_attribute :opens_at, tasking_plan.time_zone.to_tz.now + 1.hour
          result = described_class.call(task_plan: task_plan)

          expect(result.errors).to be_empty
          expect(task_plan.reload.tasks.size).to eq 3
          expect(task_plan).not_to be_out_to_students
          task_plan.tasks.each do |task|
            expect(task.opens_at).to be_within(1e-6).of(tasking_plan.opens_at)
          end
        end

        it 'does not set the first_published_at field' do
          old_published_at = task_plan.first_published_at
          publish_time = Time.current
          result = described_class.call(task_plan: task_plan, publish_time: publish_time)
          expect(result.errors).to be_empty
          task_plan.reload
          expect(task_plan.first_published_at).to eq old_published_at
          expect(task_plan.last_published_at).to be_within(1e-6).of(publish_time)
        end
      end

      context 'after the open date' do
        let(:new_title)       { 'New Title' }
        let(:new_description) { 'New Description' }
        let(:new_opens_at)    { tasking_plan.time_zone.to_tz.now.yesterday }
        let(:new_due_at)      { tasking_plan.time_zone.to_tz.now.tomorrow }
        let(:new_closes_at)   { tasking_plan.time_zone.to_tz.now.tomorrow + 1.week }

        before do
          task_plan.title = new_title
          task_plan.description = new_description
          task_plan.save!

          tasking_plan.opens_at = new_opens_at
          tasking_plan.due_at = new_due_at
          tasking_plan.closes_at = new_closes_at
          tasking_plan.save!
        end

        context 'homework' do
          before { task_plan.update_attribute :type, 'homework' }

          it 'can create or update normal and preview tasks' do
            result = described_class.call(task_plan: task_plan)

            expect(result.errors).to be_empty
            expect(task_plan.tasks.size).to eq 3
            expect(task_plan).to be_out_to_students
            gt = task_plan.grading_template
            task_plan.tasks.each do |task|
              expect(task.title).to                    eq new_title
              expect(task.description).to              eq new_description
              expect(task.opens_at).to                 be_within(1e-6).of(new_opens_at)
              expect(task.due_at).to                   be_within(1e-6).of(new_due_at)
              expect(task.closes_at).to                be_within(1e-6).of(new_closes_at)
              expect(task.auto_grading_feedback_on).to eq gt.auto_grading_feedback_on
              expect(task.manual_grading_feedback_on).to eq gt.manual_grading_feedback_on
            end
          end
        end

        context 'reading' do
          before { task_plan.update_attribute :type, 'reading' }

          it 'can create or update normal and preview tasks' do
            result = described_class.call(task_plan: task_plan)

            expect(result.errors).to be_empty
            expect(task_plan.tasks.size).to eq 3
            expect(task_plan).to be_out_to_students
            gt = task_plan.grading_template
            task_plan.tasks.each do |task|
              expect(task.title).to       eq new_title
              expect(task.description).to eq new_description
              expect(task.opens_at).to    be_within(1e-6).of(new_opens_at)
              expect(task.due_at).to      be_within(1e-6).of(new_due_at)
              expect(task.closes_at).to   be_within(1e-6).of(new_closes_at)
              expect(task.auto_grading_feedback_on).to eq gt.auto_grading_feedback_on
              expect(task.manual_grading_feedback_on).to eq gt.manual_grading_feedback_on
            end
          end
        end

        it 'does not rebuild existing tasks for the task_plan' do
          expect(task_plan.tasks.size).to eq 2
          old_tasks = task_plan.tasks.to_a

          result = described_class.call(task_plan: task_plan)
          expect(result.errors).to be_empty
          expect(task_plan.reload.tasks.size).to eq 3
          old_tasks.each { |old_task| expect(task_plan.tasks).to include old_task }
        end

        it 'does not set the first_published_at field' do
          old_published_at = task_plan.first_published_at
          publish_time = Time.current
          result = described_class.call(task_plan: task_plan, publish_time: publish_time)
          expect(result.errors).to be_empty
          expect(task_plan.reload.first_published_at).to eq old_published_at
          expect(task_plan.last_published_at).to be_within(1e-6).of(publish_time)
        end
      end
    end
  end
end
