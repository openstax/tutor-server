require 'rails_helper'

RSpec.describe Tasks::UpdateTaskCaches, type: :routine, speed: :medium do
  let(:course)                  { @task_plan.owner }
  let(:tasks)                   { @task_plan.tasks.to_a }
  let(:task_ids)                { tasks.map(&:id) }
  let(:student_tasks)           do
    tasks.select { |task| task.taskings.any? { |tasking| tasking.role.student.present? } }
  end
  let(:num_task_caches)         { student_tasks.size }
  let(:ecosystem)               { @task_plan.ecosystem }

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

    let(:book)                  { ecosystem.books.first }
    let(:chapter)               { book.chapters.first }
    let(:page)                  { chapter.pages.first }
    let(:expected_unworked_toc) do
      {
        id: ecosystem.id,
        tutor_uuid: ecosystem.tutor_uuid,
        title: ecosystem.title,
        has_exercises: true,
        num_assigned_steps: 11,
        num_assigned_known_location_steps: 8,
        num_completed_steps: 0,
        num_completed_known_location_steps: 0,
        num_assigned_exercises: 2,
        num_completed_exercises: 0,
        num_correct_exercises: 0,
        num_assigned_placeholders: 3,
        books: [
          {
            id: book.id,
            unmapped_ids: [ book.id ],
            tutor_uuid: book.tutor_uuid,
            unmapped_tutor_uuids: [ book.tutor_uuid ],
            title: book.title,
            has_exercises: true,
            num_assigned_steps: 8,
            num_completed_steps: 0,
            num_assigned_exercises: 2,
            num_completed_exercises: 0,
            num_correct_exercises: 0,
            num_assigned_placeholders: 3,
            first_worked_at: nil,
            last_worked_at: nil,
            chapters: [
              {
                id: chapter.id,
                unmapped_ids: [ chapter.id ],
                tutor_uuid: chapter.tutor_uuid,
                unmapped_tutor_uuids: [ chapter.tutor_uuid ],
                title: chapter.title,
                book_location: chapter.book_location,
                baked_book_location: chapter.baked_book_location,
                has_exercises: true,
                is_spaced_practice: false,
                num_assigned_steps: 8,
                num_completed_steps: 0,
                num_assigned_exercises: 2,
                num_completed_exercises: 0,
                num_correct_exercises: 0,
                num_assigned_placeholders: 3,
                first_worked_at: nil,
                last_worked_at: nil,
                pages: [
                  {
                    id: page.id,
                    unmapped_ids: [ page.id ],
                    tutor_uuid: page.tutor_uuid,
                    unmapped_tutor_uuids: [ page.tutor_uuid ],
                    title: page.title,
                    book_location: page.book_location,
                    baked_book_location: page.baked_book_location,
                    has_exercises: true,
                    is_spaced_practice: false,
                    num_assigned_steps: 8,
                    num_completed_steps: 0,
                    num_assigned_exercises: 2,
                    num_completed_exercises: 0,
                    num_correct_exercises: 0,
                    num_assigned_placeholders: 3,
                    first_worked_at: nil,
                    last_worked_at: nil,
                    exercises: [3, 5].map do |number|
                      {
                        id: kind_of(Integer),
                        uuid: kind_of(String),
                        question_id: kind_of(String),
                        answer_ids: kind_of(Array),
                        step_number: number,
                        group_type: kind_of(String),
                        free_response: nil,
                        selected_answer_id: nil,
                        completed: false,
                        correct: false,
                        first_completed_at: nil,
                        last_completed_at: nil
                      }
                    end
                  }
                ]
              }
            ]
          }
        ]
      }
    end
    let(:expected_worked_toc) do
      {
        id: ecosystem.id,
        tutor_uuid: ecosystem.tutor_uuid,
        title: ecosystem.title,
        has_exercises: true,
        num_assigned_steps: 11,
        num_assigned_known_location_steps: 11,
        num_completed_steps: 11,
        num_completed_known_location_steps: 11,
        num_assigned_exercises: 8,
        num_completed_exercises: 8,
        num_correct_exercises: 8,
        num_assigned_placeholders: 0,
        books: [
          {
            id: book.id,
            unmapped_ids: [ book.id ],
            tutor_uuid: book.tutor_uuid,
            unmapped_tutor_uuids: [ book.tutor_uuid ],
            title: book.title,
            has_exercises: true,
            num_assigned_steps: 11,
            num_completed_steps: 11,
            num_assigned_exercises: 8,
            num_completed_exercises: 8,
            num_correct_exercises: 8,
            num_assigned_placeholders: 0,
            first_worked_at: kind_of(String),
            last_worked_at: kind_of(String),
            chapters: [
              {
                id: chapter.id,
                unmapped_ids: [ chapter.id ],
                tutor_uuid: chapter.tutor_uuid,
                unmapped_tutor_uuids: [ chapter.tutor_uuid ],
                title: chapter.title,
                book_location: chapter.book_location,
                baked_book_location: chapter.baked_book_location,
                has_exercises: true,
                is_spaced_practice: false,
                num_assigned_steps: 11,
                num_completed_steps: 11,
                num_assigned_exercises: 8,
                num_completed_exercises: 8,
                num_correct_exercises: 8,
                num_assigned_placeholders: 0,
                first_worked_at: kind_of(String),
                last_worked_at: kind_of(String),
                pages: [
                  {
                    id: page.id,
                    unmapped_ids: [ page.id ],
                    tutor_uuid: page.tutor_uuid,
                    unmapped_tutor_uuids: [ page.tutor_uuid ],
                    title: page.title,
                    book_location: page.book_location,
                    baked_book_location: page.baked_book_location,
                    has_exercises: true,
                    is_spaced_practice: false,
                    num_assigned_steps: 11,
                    num_completed_steps: 11,
                    num_assigned_exercises: 8,
                    num_completed_exercises: 8,
                    num_correct_exercises: 8,
                    num_assigned_placeholders: 0,
                    first_worked_at: kind_of(String),
                    last_worked_at: kind_of(String),
                    exercises: [3, 5, 6, 7, 8, 9, 10, 11].map do |number|
                      {
                        id: kind_of(Integer),
                        uuid: kind_of(String),
                        question_id: kind_of(String),
                        answer_ids: kind_of(Array),
                        step_number: number,
                        group_type: kind_of(String),
                        free_response: "A sentence explaining all the things!",
                        selected_answer_id: kind_of(String),
                        completed: true,
                        correct: true,
                        first_completed_at: kind_of(String),
                        last_completed_at: kind_of(String)
                      }
                    end
                  }
                ]
              }
            ]
          }
        ]
      }
    end

    context 'preview' do
      before do
        course.update_attribute :is_preview, true
        @task_plan.update_attribute :is_preview, true
      end

      let(:queue) { :preview }

      it 'creates a Tasks::TaskCache for the given tasks' do
        Tasks::Models::TaskCache.where(tasks_task_id: task_ids).delete_all

        expect(Tasks::UpdatePeriodCaches).to receive(:set).with(queue: queue)
                                                          .and_return(Tasks::UpdatePeriodCaches)
        expect(Tasks::UpdatePeriodCaches).to receive(:perform_later)

        expect do
          described_class.call(task_ids: task_ids, queue: queue.to_s)
        end.to change { Tasks::Models::TaskCache.count }.by(num_task_caches)

        task_caches = Tasks::Models::TaskCache.where(tasks_task_id: task_ids)
        task_caches.each do |task_cache|
          task = task_cache.task
          expect(task).to be_in tasks
          expect(task_cache.task_type).to eq task.task_type
          expect(task_cache.task_plan).to eq task.task_plan
          expect(task_cache.ecosystem).to eq course.ecosystem
          expect(task_cache.student_ids).to(
            match_array task.taskings.map { |tt| tt.role.student.id }
          )
          expect(task_cache.teacher_student_ids).to eq []
          expect(task_cache.student_names).to match_array(
            task.taskings.map { |tt| tt.role.student.name }
          )

          expect(task_cache.as_toc.deep_symbolize_keys).to match expected_unworked_toc

          expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
          expect(task_cache.due_at).to be_within(1).of(task.due_at)
          expect(task_cache.closes_at).to be_within(1).of(task.closes_at)
          expect(task_cache.auto_grading_feedback_on).to eq task.auto_grading_feedback_on
          expect(task_cache.manual_grading_feedback_on).to eq task.manual_grading_feedback_on
          expect(task_cache.withdrawn_at).to be_nil
          expect(task_cache.is_cached_for_period).to eq false
        end
      end

      it 'updates existing Tasks::TaskCaches for the given tasks' do
        task_caches = Tasks::Models::TaskCache.where(tasks_task_id: task_ids)
        expect(task_caches.count).to eq num_task_caches

        task_caches.each do |task_cache|
          task = task_cache.task
          expect(task).to be_in tasks
          expect(task_cache.task_type).to eq task.task_type
          expect(task_cache.task_plan).to eq task.task_plan
          expect(task_cache.ecosystem).to eq course.ecosystem
          expect(task_cache.student_ids).to(
            match_array task.taskings.map { |tt| tt.role.student.id }
          )
          expect(task_cache.teacher_student_ids).to eq []
          expect(task_cache.student_names).to match_array(
            task.taskings.map { |tt| tt.role.student.name }
          )

          expect(task_cache.as_toc.deep_symbolize_keys).to match expected_unworked_toc

          expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
          expect(task_cache.due_at).to be_within(1).of(task.due_at)
          expect(task_cache.closes_at).to be_within(1).of(task.closes_at)
          expect(task_cache.auto_grading_feedback_on).to eq task.auto_grading_feedback_on
          expect(task_cache.manual_grading_feedback_on).to eq task.manual_grading_feedback_on
          expect(task_cache.withdrawn_at).to be_nil
          expect(task_cache.is_cached_for_period).to eq true
        end

        first_task = student_tasks.first
        Preview::WorkTask.call(task: first_task, is_correct: true)

        expect(Tasks::UpdatePeriodCaches).to receive(:set).with(queue: queue)
                                                          .and_return(Tasks::UpdatePeriodCaches)
        expect(Tasks::UpdatePeriodCaches).to receive(:perform_later)

        expect { described_class.call(task_ids: task_ids, queue: queue.to_s) }.not_to(
          change { Tasks::Models::TaskCache.count }
        )

        task_caches.each do |task_cache|
          task = task_cache.reload.task
          is_first_task = task == first_task

          expect(task).to be_in tasks
          expect(task_cache.task_type).to eq task.task_type
          expect(task_cache.task_plan).to eq task.task_plan
          expect(task_cache.ecosystem).to eq course.ecosystem
          expect(task_cache.student_ids).to(
            match_array task.taskings.map { |tt| tt.role.student.id }
          )
          expect(task_cache.teacher_student_ids).to eq []

          expect(task_cache.as_toc.deep_symbolize_keys).to match(
            is_first_task ? expected_worked_toc : expected_unworked_toc
          )

          expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
          expect(task_cache.due_at).to be_within(1).of(task.due_at)
          expect(task_cache.closes_at).to be_within(1).of(task.closes_at)
          expect(task_cache.auto_grading_feedback_on).to eq task.auto_grading_feedback_on
          expect(task_cache.manual_grading_feedback_on).to eq task.manual_grading_feedback_on
          expect(task_cache.withdrawn_at).to be_nil
          expect(task_cache.is_cached_for_period).to eq false
        end
      end

      it 'is called when a task_plan is published' do
        @task_plan.tasks.delete_all

        expect(configured_job).to receive(:perform_later) do |task_ids:, queue:|
          expect(task_ids).to match_array(@task_plan.tasks.reset.pluck(:id))
          expect(queue).to eq queue.to_s
        end

        DistributeTasks.call(task_plan: @task_plan)
      end

      it 'is called when a task step is updated' do
        task = @task_plan.tasks.first
        expect(configured_job).to receive(:perform_later).with(
          task_ids: task.id, update_step_counts: true, queue: queue.to_s
        )

        tasked_exercise = task.tasked_exercises.first
        tasked_exercise.free_response = 'Something'
        tasked_exercise.save!
      end

      it 'is called when a task step is marked as completed' do
        task = @task_plan.tasks.first
        expect(configured_job).to receive(:perform_later).with(
          task_ids: task.id, update_step_counts: true, queue: queue.to_s
        )

        task_step = task.task_steps.first
        MarkTaskStepCompleted.call(task_step: task_step)
      end

      it 'is called when placeholder steps are populated' do
        task = @task_plan.tasks.first
        expect(configured_job).to receive(:perform_later).once.with(
          task_ids: task.id, update_step_counts: false, queue: queue.to_s
        )

        Tasks::PopulatePlaceholderSteps.call(task: task)
      end

      it 'is called when a new ecosystem is added to the course' do
        ecosystem = course.ecosystem
        course.course_ecosystems.delete_all :delete_all

        expect(configured_job).to receive(:perform_later) do |task_ids:, queue:|
          student_task_ids = @task_plan.tasks.filter do |task|
            task.taskings.any? { |tasking| tasking.role.student.present? }
          end.map(&:id)
          expect(task_ids).to match_array(student_task_ids)
          expect(queue).to eq queue.to_s
        end

        AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
      end

      it 'is called when a new student joins the course' do
        student_user = FactoryBot.create :user_profile
        period = course.periods.first
        existing_task_ids = tasks.map(&:id)
        expect(configured_job).to receive(:perform_later) do |task_ids:, queue:|
          expect(task_ids.size).to eq 1
          expect(queue).to eq queue.to_s
          expect(existing_task_ids).not_to include task_ids.first
        end

        AddUserAsPeriodStudent.call(user: student_user, period: period)
      end
    end

    context 'not preview' do
      let(:queue) { :dashboard }

      it 'creates a Tasks::TaskCache for the given tasks' do
        Tasks::Models::TaskCache.where(tasks_task_id: task_ids).delete_all

        expect(Tasks::UpdatePeriodCaches).to receive(:set).with(queue: queue)
                                                          .and_return(Tasks::UpdatePeriodCaches)
        expect(Tasks::UpdatePeriodCaches).to receive(:perform_later)

        expect { described_class.call(task_ids: task_ids, queue: queue.to_s) }
          .to change { Tasks::Models::TaskCache.count }.by(num_task_caches)

        task_caches = Tasks::Models::TaskCache.where(tasks_task_id: task_ids)
        task_caches.each do |task_cache|
          task = task_cache.task
          expect(task).to be_in tasks
          expect(task_cache.task_type).to eq task.task_type
          expect(task_cache.task_plan).to eq task.task_plan
          expect(task_cache.ecosystem).to eq course.ecosystem
          expect(task_cache.student_ids).to(
            match_array task.taskings.map { |tt| tt.role.student.id }
          )
          expect(task_cache.teacher_student_ids).to eq []
          expect(task_cache.student_names).to match_array(
            task.taskings.map { |tt| tt.role.student.name }
          )

          expect(task_cache.as_toc.deep_symbolize_keys).to match expected_unworked_toc

          expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
          expect(task_cache.due_at).to be_within(1).of(task.due_at)
          expect(task_cache.closes_at).to be_within(1).of(task.closes_at)
          expect(task_cache.auto_grading_feedback_on).to eq task.auto_grading_feedback_on
          expect(task_cache.manual_grading_feedback_on).to eq task.manual_grading_feedback_on
          expect(task_cache.withdrawn_at).to be_nil
          expect(task_cache.is_cached_for_period).to eq false
        end
      end

      it 'updates existing Tasks::TaskCaches for the given tasks' do
        task_caches = Tasks::Models::TaskCache.where(tasks_task_id: task_ids)
        expect(task_caches.count).to eq num_task_caches

        task_caches.each do |task_cache|
          task = task_cache.task
          expect(task).to be_in tasks
          expect(task_cache.task_type).to eq task.task_type
          expect(task_cache.task_plan).to eq task.task_plan
          expect(task_cache.ecosystem).to eq course.ecosystem
          expect(task_cache.student_ids).to(
            match_array task.taskings.map { |tt| tt.role.student.id }
          )
          expect(task_cache.teacher_student_ids).to eq []
          expect(task_cache.student_names).to match_array(
            task.taskings.map { |tt| tt.role.student.name }
          )

          expect(task_cache.as_toc.deep_symbolize_keys).to match expected_unworked_toc

          expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
          expect(task_cache.due_at).to be_within(1).of(task.due_at)
          expect(task_cache.closes_at).to be_within(1).of(task.closes_at)
          expect(task_cache.auto_grading_feedback_on).to eq task.auto_grading_feedback_on
          expect(task_cache.manual_grading_feedback_on).to eq task.manual_grading_feedback_on
          expect(task_cache.withdrawn_at).to be_nil
          expect(task_cache.is_cached_for_period).to eq true
        end

        first_task = student_tasks.first
        Preview::WorkTask.call(task: first_task, is_correct: true)

        expect(Tasks::UpdatePeriodCaches).to receive(:set).with(queue: queue)
                                                          .and_return(Tasks::UpdatePeriodCaches)
        expect(Tasks::UpdatePeriodCaches).to receive(:perform_later)

        expect { described_class.call(task_ids: task_ids, queue: queue.to_s) }.not_to(
          change { Tasks::Models::TaskCache.count }
        )

        task_caches.each do |task_cache|
          task = task_cache.reload.task
          is_first_task = task == first_task

          expect(task).to be_in tasks
          expect(task_cache.task_type).to eq task.task_type
          expect(task_cache.task_plan).to eq task.task_plan
          expect(task_cache.ecosystem).to eq course.ecosystem
          expect(task_cache.student_ids).to(
            match_array task.taskings.map { |tt| tt.role.student.id }
          )
          expect(task_cache.teacher_student_ids).to eq []

          expect(task_cache.as_toc.deep_symbolize_keys).to match(
            is_first_task ? expected_worked_toc : expected_unworked_toc
          )

          expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
          expect(task_cache.due_at).to be_within(1).of(task.due_at)
          expect(task_cache.closes_at).to be_within(1).of(task.closes_at)
          expect(task_cache.auto_grading_feedback_on).to eq task.auto_grading_feedback_on
          expect(task_cache.manual_grading_feedback_on).to eq task.manual_grading_feedback_on
          expect(task_cache.withdrawn_at).to be_nil
          expect(task_cache.is_cached_for_period).to eq false
        end
      end

      it 'is called when a task_plan is published' do
        @task_plan.tasks.delete_all

        expect(configured_job).to receive(:perform_later) do |task_ids:, queue:|
          expect(task_ids).to match_array(@task_plan.tasks.reset.pluck(:id))
          expect(queue).to eq queue.to_s
        end

        DistributeTasks.call(task_plan: @task_plan)
      end

      it 'is called when a task step is updated' do
        task = @task_plan.tasks.first
        expect(configured_job).to receive(:perform_later).with(
          task_ids: task.id, update_step_counts: true, queue: queue.to_s
        )

        tasked_exercise = task.tasked_exercises.first
        tasked_exercise.free_response = 'Something'
        tasked_exercise.save!
      end

      it 'is called when a task step is marked as completed' do
        task = @task_plan.tasks.first
        expect(configured_job).to(
          receive(:perform_later).with(
            task_ids: task.id, update_step_counts: true, queue: queue.to_s
          )
        )

        task_step = task.task_steps.first
        MarkTaskStepCompleted.call(task_step: task_step)
      end

      it 'is called when placeholder steps are populated' do
        task = @task_plan.tasks.first
        expect(configured_job).to(
          receive(:perform_later).once.with(
            task_ids: task.id, update_step_counts: false, queue: queue.to_s
          )
        )

        Tasks::PopulatePlaceholderSteps.call(task: task)
      end

      it 'is called when a new ecosystem is added to the course' do
        ecosystem = course.ecosystem
        course.course_ecosystems.delete_all :delete_all

        expect(configured_job).to receive(:perform_later) do |task_ids:, queue:|
          student_task_ids = @task_plan.tasks.filter do |task|
            task.taskings.any? { |tasking| tasking.role.student.present? }
          end.map(&:id)
          expect(task_ids).to match_array(student_task_ids)
          expect(queue).to eq queue.to_s
        end

        AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
      end

      it 'is called when a new student joins the course' do
        student_user = FactoryBot.create :user_profile
        period = course.periods.first
        existing_task_ids = tasks.map(&:id)
        expect(configured_job).to receive(:perform_later) do |task_ids:, queue:|
          expect(task_ids.size).to eq 1
          expect(queue).to eq queue.to_s
          expect(existing_task_ids).not_to include task_ids.first
        end

        AddUserAsPeriodStudent.call(user: student_user, period: period)
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

    let(:expected_unworked_toc) do
      {
        id: ecosystem.id,
        tutor_uuid: ecosystem.tutor_uuid,
        title: ecosystem.title,
        has_exercises: false,
        num_assigned_steps: 1,
        num_assigned_known_location_steps: 0,
        num_completed_steps: 0,
        num_completed_known_location_steps: 0,
        num_assigned_exercises: 0,
        num_completed_exercises: 0,
        num_correct_exercises: 0,
        num_assigned_placeholders: 0,
        books: []
      }
    end
    let(:expected_worked_toc) do
      {
        id: ecosystem.id,
        tutor_uuid: ecosystem.tutor_uuid,
        title: ecosystem.title,
        has_exercises: false,
        num_assigned_steps: 1,
        num_assigned_known_location_steps: 0,
        num_completed_steps: 1,
        num_completed_known_location_steps: 0,
        num_assigned_exercises: 0,
        num_completed_exercises: 0,
        num_correct_exercises: 0,
        num_assigned_placeholders: 0,
        books: []
      }
    end

    it 'creates a Tasks::TaskCache for the given tasks' do
      Tasks::Models::TaskCache.where(tasks_task_id: task_ids).delete_all

      expect(Tasks::UpdatePeriodCaches).to receive(:set).and_return(Tasks::UpdatePeriodCaches)
      expect(Tasks::UpdatePeriodCaches).to receive(:perform_later)

      expect { described_class.call(task_ids: task_ids) }
        .to change { Tasks::Models::TaskCache.count }.by(num_task_caches)

      task_caches = Tasks::Models::TaskCache.where(tasks_task_id: task_ids)
      task_caches.each do |task_cache|
        task = task_cache.task
        expect(task).to be_in tasks
        expect(task_cache.task_type).to eq task.task_type
        expect(task_cache.task_plan).to eq task.task_plan
        expect(task_cache.ecosystem).to eq course.ecosystem
        expect(task_cache.student_ids).to match_array task.taskings.map { |tt| tt.role.student.id }
        expect(task_cache.teacher_student_ids).to eq []
        expect(task_cache.student_names).to match_array(
          task.taskings.map { |tt| tt.role.student.name }
        )

        expect(task_cache.as_toc.deep_symbolize_keys).to match expected_unworked_toc

        expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
        expect(task_cache.due_at).to be_within(1).of(task.due_at)
        expect(task_cache.closes_at).to be_within(1).of(task.closes_at)
        expect(task_cache.auto_grading_feedback_on).to eq task.auto_grading_feedback_on
        expect(task_cache.manual_grading_feedback_on).to eq task.manual_grading_feedback_on
        expect(task_cache.withdrawn_at).to be_nil
        expect(task_cache.is_cached_for_period).to eq false
      end
    end

    it 'updates existing Tasks::TaskCaches for the given tasks' do
      task_caches = Tasks::Models::TaskCache.where(tasks_task_id: task_ids)
      expect(task_caches.count).to eq num_task_caches

      task_caches.each do |task_cache|
        task = task_cache.task
        expect(task).to be_in tasks
        expect(task_cache.task_type).to eq task.task_type
        expect(task_cache.task_plan).to eq task.task_plan
        expect(task_cache.ecosystem).to eq course.ecosystem
        expect(task_cache.student_ids).to match_array task.taskings.map { |tt| tt.role.student.id }
        expect(task_cache.teacher_student_ids).to eq []
        expect(task_cache.student_names).to match_array(
          task.taskings.map { |tt| tt.role.student.name }
        )

        expect(task_cache.as_toc.deep_symbolize_keys).to match expected_unworked_toc

        expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
        expect(task_cache.due_at).to be_within(1).of(task.due_at)
        expect(task_cache.closes_at).to be_within(1).of(task.closes_at)
        expect(task_cache.auto_grading_feedback_on).to eq task.auto_grading_feedback_on
        expect(task_cache.manual_grading_feedback_on).to eq task.manual_grading_feedback_on
        expect(task_cache.withdrawn_at).to be_nil
        expect(task_cache.is_cached_for_period).to eq true
      end

      first_task = student_tasks.first
      Preview::WorkTask.call(task: first_task, is_correct: true)

      expect(Tasks::UpdatePeriodCaches).to receive(:set).and_return(Tasks::UpdatePeriodCaches)
      expect(Tasks::UpdatePeriodCaches).to receive(:perform_later)

      expect { described_class.call(task_ids: task_ids) }.not_to(
        change { Tasks::Models::TaskCache.count }
      )

      task_caches.each do |task_cache|
        task = task_cache.reload.task
        is_first_task = task == first_task

        expect(task).to be_in tasks
        expect(task_cache.task_type).to eq task.task_type
        expect(task_cache.task_plan).to eq task.task_plan
        expect(task_cache.ecosystem).to eq course.ecosystem
        expect(task_cache.student_ids).to match_array task.taskings.map { |tt| tt.role.student.id }
        expect(task_cache.teacher_student_ids).to eq []

        expect(task_cache.as_toc.deep_symbolize_keys).to match(
          is_first_task ? expected_worked_toc : expected_unworked_toc
        )

        expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
        expect(task_cache.due_at).to be_within(1).of(task.due_at)
        expect(task_cache.closes_at).to be_within(1).of(task.closes_at)
        expect(task_cache.auto_grading_feedback_on).to eq task.auto_grading_feedback_on
        expect(task_cache.manual_grading_feedback_on).to eq task.manual_grading_feedback_on
        expect(task_cache.withdrawn_at).to be_nil
        expect(task_cache.is_cached_for_period).to eq false
      end
    end
  end
end
