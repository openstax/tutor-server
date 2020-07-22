require 'rails_helper'

RSpec.describe DistributeTasks, type: :routine, truncation: true, speed: :medium do
  let(:course)    { FactoryBot.create :course_profile_course }
  let(:period)    { FactoryBot.create :course_membership_period, course: course }
  let!(:user)     do
    FactoryBot.create(:user_profile).tap do |user|
      AddUserAsPeriodStudent.call(user: user, period: period)
    end
  end
  let!(:new_user) do
    FactoryBot.create(:user_profile).tap do |user|
      AddUserAsPeriodStudent.call(user: user, period: period)
    end
  end
  let(:reading_plan) do
    FactoryBot.build(:tasks_task_plan, course: course).tap do |reading_plan|
      reading_plan.tasking_plans.first.target = period
      reading_plan.save!
    end
  end
  let(:reading_tasking_plan) { reading_plan.tasking_plans.first }
  let(:teacher_student_role) do
    FactoryBot.create(:course_membership_teacher_student, period: period).role
  end

  let(:homework_plan) do
    FactoryBot.build(
      :tasks_task_plan,
      assistant: FactoryBot.create(
        :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
      ),
      course: course,
      type: 'homework',
      ecosystem: @ecosystem,
      settings: {
        exercises: exercises[0..5].map do |exercise|
          { id: exercise.id.to_s, points: [ 1 ] * exercise.number_of_questions }
        end,
        exercises_count_dynamic: 3
      }
    ).tap do |homework_plan|
      homework_plan.tasking_plans.first.target = period
      homework_plan.save!
    end
  end
  let(:homework_tasking_plan) { homework_plan.tasking_plans.first }
  let(:exercise_ids) { @pages.flat_map(&:homework_core_exercise_ids) }
  let(:exercises)    { Content::Models::Exercise.where(id: exercise_ids) }

  context 'with no teacher_student roles' do
    context 'homework' do
      before do
        allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
          receive(:num_spaced_practice_exercises) { 3 }
        )

        generate_homework_test_exercise_content

        AddEcosystemToCourse.call ecosystem: @ecosystem, course: course
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

        AddEcosystemToCourse.call ecosystem: @ecosystem, course: course
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

      it 'updating due dates causes student scores to change and Glicko jobs to re-queue' do
        # 3 tasks, called twice
        expect(Ratings::UpdateRoleBookParts).to(
          receive(:set).and_return(Ratings::UpdateRoleBookParts)
        ).exactly(6).times
        expect(Ratings::UpdateRoleBookParts).to(
          receive(:perform_later).exactly(6).times.and_call_original
        )

        # teacher_student tasks don't count here
        expect(Ratings::UpdatePeriodBookParts).to(
          receive(:set).and_return(Ratings::UpdatePeriodBookParts)
        ).exactly(4).times
        expect(Ratings::UpdatePeriodBookParts).to(
          receive(:perform_later).exactly(4).times.and_call_original
        )

        homework_plan.grading_template.update_column :late_work_penalty, 1.0
        homework_tasking_plan.opens_at = homework_tasking_plan.time_zone.now - 2.hours
        homework_tasking_plan.due_at = homework_tasking_plan.time_zone.now - 1.hour
        homework_tasking_plan.save validate: false
        result = described_class.call(task_plan: homework_plan)

        expect(result.errors).to be_empty
        expect(homework_plan.reload.tasks.size).to eq 3
        expect(homework_plan).to be_out_to_students
        homework_plan.tasks.each do |task|
          expect(task).to be_past_due
          expect(task.steps_count).to eq 9
          expect(task.exercise_steps_count).to eq 6
          expect(task.points_without_lateness).to eq 0.0
          expect(task.points).to eq 0.0
          expect(task.score_without_lateness).to eq 0.0
          expect(task.score).to eq 0.0

          Preview::WorkTask.call task: task, is_correct: true

          expect(task.reload.exercise_steps_count).to eq 9
          expect(task.completed_steps_count).to eq 9
          expect(task.completed_on_time_steps_count).to eq 0
          expect(task.correct_exercise_steps_count).to eq 9
          expect(task.correct_on_time_exercise_steps_count).to eq 0
          expect(task.points_without_lateness).to eq 9.0
          expect(task.points).to eq 0.0
          expect(task.score_without_lateness).to eq 1.0
          expect(task.score).to eq 0.0
        end

        homework_tasking_plan.update_attribute :due_at, homework_tasking_plan.time_zone.now + 1.hour
        result = described_class.call(task_plan: homework_plan)

        expect(result.errors).to be_empty
        expect(homework_plan.reload.tasks.size).to eq 3
        homework_plan.tasks.each do |task|
          expect(task).not_to be_past_due
          expect(task.steps_count).to eq 9
          expect(task.exercise_steps_count).to eq 9
          expect(task.completed_steps_count).to eq 9
          expect(task.completed_on_time_steps_count).to eq 0
          expect(task.correct_exercise_steps_count).to eq 9
          expect(task.correct_on_time_exercise_steps_count).to eq 0
          expect(task.points_without_lateness).to eq 9.0
          expect(task.points).to eq 9.0
          expect(task.score_without_lateness).to eq 1.0
          expect(task.score).to eq 1.0
        end
      end
    end

    context 'unpublished task_plan' do
      before { expect(reading_plan).not_to be_out_to_students }

      context 'before the open date' do
        before do
          opens_at = Time.current.tomorrow
          reading_plan.tasking_plans.each { |tp| tp.update_attribute(:opens_at, opens_at) }
          reading_plan.tasks.each { |task| task.update_attribute(:opens_at, opens_at) }
        end

        context 'preview' do
          before { teacher_student_role }

          it 'can create or update a preview task' do
            expect(reading_plan.tasks).to be_empty
            result = described_class.call(task_plan: reading_plan, preview: true)

            expect(result.errors).to be_empty
            expect(reading_plan.reload.tasks.size).to eq 1
            expect(reading_plan).not_to be_out_to_students
            task = reading_plan.tasks.first
            expect(task.taskings.first.role).to eq teacher_student_role
            expect(task.opens_at).to be_within(1e-6).of(reading_tasking_plan.opens_at)

            reading_tasking_plan.update_attribute(
              :opens_at, reading_tasking_plan.time_zone.now + 1.hour
            )
            result = described_class.call(task_plan: reading_plan, preview: true)

            expect(result.errors).to be_empty
            expect(reading_plan.reload.tasks.size).to eq 1
            expect(reading_plan).not_to be_out_to_students
            task = reading_plan.tasks.first
            expect(task.taskings.first.role).to eq teacher_student_role
            expect(task.opens_at).to be_within(1e-6).of(reading_tasking_plan.opens_at)
          end

          it 'does not save plan if it is new' do
            new_plan = reading_plan.dup
            result = described_class.call(task_plan: new_plan, preview: true)
            expect(result.errors).to be_empty
            expect(new_plan).to be_new_record
          end
        end

        it 'can create or update normal and preview tasks' do
          reading_tasking_plan.update_attribute(
            :opens_at, reading_tasking_plan.time_zone.now + 1.hour
          )
          result = described_class.call(task_plan: reading_plan)

          expect(result.errors).to be_empty
          expect(reading_plan.reload.tasks.size).to eq 3
          expect(reading_plan).not_to be_out_to_students
          reading_plan.tasks.each do |task|
            expect(task.opens_at).to be_within(1e-6).of(reading_tasking_plan.opens_at)
          end
        end

        it 'sets the published_at fields' do
          publish_time = Time.current
          result = described_class.call(task_plan: reading_plan, publish_time: publish_time)
          expect(result.errors).to be_empty
          reading_plan.reload
          expect(reading_plan.first_published_at).to be_within(1).of(publish_time)
          expect(reading_plan.last_published_at).to be_within(1).of(publish_time)
        end

        it 'fails to publish the task_plan if one or more non-stepless tasks would be empty' do
          original_build_tasks = DummyAssistant.instance_method(:build_tasks)
          allow_any_instance_of(DummyAssistant).to receive(:build_tasks) do |receiver|
            tasks = original_build_tasks.bind(receiver).call
            tasks.each { |task| task.task_type = :reading }
          end

          expect(reading_plan.tasks).to be_empty
          result = described_class.call(task_plan: reading_plan)
          expect(result.errors.first.code).to eq :empty_tasks
          expect(reading_plan.tasks).to be_empty
        end
      end

      context 'after the open date' do
        before do
          opens_at = Time.current.yesterday
          reading_plan.tasking_plans.each { |tp| tp.update_attribute(:opens_at, opens_at) }
          reading_plan.tasks.each { |task| task.update_attribute(:opens_at, opens_at) }
        end

        it 'can create or update normal and preview tasks' do
          # No work done
          expect(Ratings::UpdateRoleBookParts).not_to receive(:set)
          expect(Ratings::UpdatePeriodBookParts).not_to receive(:set)

          reading_tasking_plan.update_attribute(
            :opens_at, reading_tasking_plan.time_zone.now - 1.hour
          )
          result = described_class.call(task_plan: reading_plan)

          expect(result.errors).to be_empty
          expect(reading_plan.reload.tasks.size).to eq 3
          expect(reading_plan).to be_out_to_students
          reading_plan.tasks.each do |task|
            expect(task.opens_at).to be_within(1e-6).of(reading_tasking_plan.opens_at)
          end

          reading_tasking_plan.update_attribute :due_at, reading_tasking_plan.time_zone.now + 1.hour
          result = described_class.call(task_plan: reading_plan)

          expect(result.errors).to be_empty
          expect(reading_plan.reload.tasks.size).to eq 3
          expect(reading_plan).to be_out_to_students
          reading_plan.tasks.each do |task|
            expect(task.due_at).to be_within(1e-6).of(reading_tasking_plan.due_at)
          end
        end

        it 'sets the published_at fields' do
          publish_time = Time.current
          result = described_class.call(task_plan: reading_plan, publish_time: publish_time)
          expect(result.errors).to be_empty
          reading_plan.reload
          expect(reading_plan.first_published_at).to be_within(1).of(publish_time)
          expect(reading_plan.last_published_at).to be_within(1).of(publish_time)
        end

        it 'fails to publish the task_plan if one or more non-stepless tasks would be empty' do
          original_build_tasks = DummyAssistant.instance_method(:build_tasks)
          allow_any_instance_of(DummyAssistant).to receive(:build_tasks) do |receiver|
            tasks = original_build_tasks.bind(receiver).call
            tasks.each { |task| task.task_type = :reading }
          end

          expect(reading_plan.tasks).to be_empty
          result = described_class.call(task_plan: reading_plan)
          expect(result.errors.first.code).to eq :empty_tasks
          expect(reading_plan.tasks).to be_empty
        end
      end
    end

    context 'published task_plan' do
      before do
        described_class.call(task_plan: reading_plan)
        new_user.roles.each { |role| role.taskings.each { |tasking| tasking.task.really_destroy! } }
        expect(reading_plan.reload).to be_out_to_students
      end

      context 'before the open date' do
        before do
          opens_at = Time.current.tomorrow
          reading_plan.tasking_plans.each { |tp| tp.update_attribute(:opens_at, opens_at) }
          reading_plan.tasks.each { |task| task.update_attribute(:opens_at, opens_at) }
        end

        it 'can create or update normal and preview tasks' do
          reading_tasking_plan.update_attribute(
            :opens_at, reading_tasking_plan.time_zone.now + 1.hour
          )
          result = described_class.call(task_plan: reading_plan)

          expect(result.errors).to be_empty
          expect(reading_plan.reload.tasks.size).to eq 3
          expect(reading_plan).not_to be_out_to_students
          reading_plan.tasks.each do |task|
            expect(task.opens_at).to be_within(1e-6).of(reading_tasking_plan.opens_at)
          end
        end

        it 'does not set the first_published_at field' do
          old_published_at = reading_plan.first_published_at
          publish_time = Time.current
          result = described_class.call(task_plan: reading_plan, publish_time: publish_time)
          expect(result.errors).to be_empty
          reading_plan.reload
          expect(reading_plan.first_published_at).to eq old_published_at
          expect(reading_plan.last_published_at).to be_within(1e-6).of(publish_time)
        end
      end

      context 'after the open date' do
        let(:new_title)       { 'New Title' }
        let(:new_description) { 'New Description' }
        let(:new_opens_at)    { reading_tasking_plan.time_zone.now.yesterday }
        let(:new_due_at)      { reading_tasking_plan.time_zone.now.tomorrow }
        let(:new_closes_at)   { reading_tasking_plan.time_zone.now.tomorrow + 1.week }

        context 'homework' do
          before do
            allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
              receive(:num_spaced_practice_exercises) { 3 }
            )

            generate_homework_test_exercise_content

            AddEcosystemToCourse.call ecosystem: @ecosystem, course: course

            homework_plan.title = new_title
            homework_plan.description = new_description
            homework_plan.save!

            homework_tasking_plan.opens_at = new_opens_at
            homework_tasking_plan.due_at = new_due_at
            homework_tasking_plan.closes_at = new_closes_at
            homework_tasking_plan.save!
          end

          it 'can create or update normal and preview tasks' do
            # No work done
            expect(Ratings::UpdateRoleBookParts).not_to receive(:set)
            expect(Ratings::UpdatePeriodBookParts).not_to receive(:set)

            result = described_class.call task_plan: homework_plan

            expect(result.errors).to be_empty
            expect(homework_plan.tasks.size).to eq 3
            expect(homework_plan).to be_out_to_students
            gt = homework_plan.grading_template
            homework_plan.tasks.each do |task|
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
          before do
            reading_plan.title = new_title
            reading_plan.description = new_description
            reading_plan.save!

            reading_tasking_plan.opens_at = new_opens_at
            reading_tasking_plan.due_at = new_due_at
            reading_tasking_plan.closes_at = new_closes_at
            reading_tasking_plan.save!

            reading_plan.reload
          end

          it 'can create or update normal and preview tasks' do
            # No work done
            expect(Ratings::UpdateRoleBookParts).not_to receive(:set)
            expect(Ratings::UpdatePeriodBookParts).not_to receive(:set)

            result = described_class.call(task_plan: reading_plan)

            expect(result.errors).to be_empty
            expect(reading_plan.tasks.size).to eq 3
            expect(reading_plan).to be_out_to_students
            gt = reading_plan.grading_template
            reading_plan.tasks.each do |task|
              expect(task.title).to       eq new_title
              expect(task.description).to eq new_description
              expect(task.opens_at).to    be_within(1e-6).of(new_opens_at)
              expect(task.due_at).to      be_within(1e-6).of(new_due_at)
              expect(task.closes_at).to   be_within(1e-6).of(new_closes_at)
              expect(task.auto_grading_feedback_on).to eq gt.auto_grading_feedback_on
              expect(task.manual_grading_feedback_on).to eq gt.manual_grading_feedback_on
            end
          end

          it 'does not rebuild existing tasks for the task_plan' do
            expect(reading_plan.tasks.size).to eq 2
            old_tasks = reading_plan.tasks.to_a

            result = described_class.call(task_plan: reading_plan)
            expect(result.errors).to be_empty
            expect(reading_plan.reload.tasks.size).to eq 3
            old_tasks.each { |old_task| expect(reading_plan.tasks).to include old_task }
          end

          it 'does not set the first_published_at field' do
            old_published_at = reading_plan.first_published_at
            publish_time = Time.current
            result = described_class.call(task_plan: reading_plan, publish_time: publish_time)
            expect(result.errors).to be_empty
            expect(reading_plan.reload.first_published_at).to eq old_published_at
            expect(reading_plan.last_published_at).to be_within(1e-6).of(publish_time)
          end

          it 'queues Tasks::UpdateTaskCaches jobs to run on the new due date when updating' do
            existing_tasks = reading_plan.tasks.to_a
            expect(existing_tasks.size).to eq 2
            existing_tasks.each { |task| expect(task.task_cache_job_id).to be_nil }

            Delayed::Worker.with_delay_jobs(true) do
              described_class.call task_plan: reading_plan.reload
            end

            existing_tasks.each { |task| expect(task.reload.task_cache_job_id).not_to be_nil }

            jobs = Delayed::Job.where(id: existing_tasks.map(&:task_cache_job_id))
            expect(jobs.size).to eq existing_tasks.size
            jobs.each { |job| expect(job.run_at).to be_within(1).of(new_due_at) }
          end
        end
      end
    end
  end
end
