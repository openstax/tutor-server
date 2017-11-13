require 'rails_helper'

RSpec.describe Tasks::UpdateTaskCaches, type: :routine, speed: :slow do
  before(:all) { @task_plan = FactoryBot.create :tasked_task_plan }

  let(:tasks)                 { @task_plan.tasks.to_a }
  let(:task_ids)              { tasks.map(&:id) }
  let(:student_tasks)         do
    tasks.select { |task| task.taskings.any? { |tasking| tasking.role.student.present? } }
  end
  let(:num_task_caches)       { student_tasks.size }
  let(:ecosystem)             { @task_plan.ecosystem }
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
      num_completed_steps: 0,
      num_assigned_exercises: 2,
      num_completed_exercises: 0,
      num_correct_exercises: 0,
      num_assigned_placeholders: 3,
      books: [
        {
          id: book.id,
          tutor_uuid: book.tutor_uuid,
          title: book.title,
          has_exercises: true,
          num_assigned_steps: 8,
          num_completed_steps: 0,
          num_assigned_exercises: 2,
          num_completed_exercises: 0,
          num_correct_exercises: 0,
          num_assigned_placeholders: 3,
          chapters: [
            {
              id: chapter.id,
              tutor_uuid: chapter.tutor_uuid,
              title: chapter.title,
              book_location: chapter.book_location,
              has_exercises: true,
              is_spaced_practice: false,
              num_assigned_steps: 8,
              num_completed_steps: 0,
              num_assigned_exercises: 2,
              num_completed_exercises: 0,
              num_correct_exercises: 0,
              num_assigned_placeholders: 3,
              pages: [
                {
                  id: page.id,
                  tutor_uuid: page.tutor_uuid,
                  title: page.title,
                  book_location: page.book_location,
                  has_exercises: true,
                  is_spaced_practice: false,
                  is_intro: false,
                  num_assigned_steps: 8,
                  num_completed_steps: 0,
                  num_assigned_exercises: 2,
                  num_completed_exercises: 0,
                  num_correct_exercises: 0,
                  num_assigned_placeholders: 3,
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
                      correct: false
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
      num_completed_steps: 11,
      num_assigned_exercises: 8,
      num_completed_exercises: 8,
      num_correct_exercises: 8,
      num_assigned_placeholders: 0,
      books: [
        {
          id: book.id,
          tutor_uuid: book.tutor_uuid,
          title: book.title,
          has_exercises: true,
          num_assigned_steps: 11,
          num_completed_steps: 11,
          num_assigned_exercises: 8,
          num_completed_exercises: 8,
          num_correct_exercises: 8,
          num_assigned_placeholders: 0,
          chapters: [
            {
              id: chapter.id,
              tutor_uuid: chapter.tutor_uuid,
              title: chapter.title,
              book_location: chapter.book_location,
              has_exercises: true,
              is_spaced_practice: false,
              num_assigned_steps: 11,
              num_completed_steps: 11,
              num_assigned_exercises: 8,
              num_completed_exercises: 8,
              num_correct_exercises: 8,
              num_assigned_placeholders: 0,
              pages: [
                {
                  id: page.id,
                  tutor_uuid: page.tutor_uuid,
                  title: page.title,
                  book_location: page.book_location,
                  has_exercises: true,
                  is_spaced_practice: false,
                  is_intro: false,
                  num_assigned_steps: 11,
                  num_completed_steps: 11,
                  num_assigned_exercises: 8,
                  num_completed_exercises: 8,
                  num_correct_exercises: 8,
                  num_assigned_placeholders: 0,
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
                      correct: true
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

  it 'creates a Tasks::TaskCache for the given tasks' do
    Tasks::Models::TaskCache.where(tasks_task_id: task_ids).delete_all

    expect { described_class.call(tasks: tasks) }
      .to change { Tasks::Models::TaskCache.count }.by(num_task_caches)

    task_caches = Tasks::Models::TaskCache.where(tasks_task_id: task_ids)
    task_caches.each do |task_cache|
      task = task_cache.task
      expect(task).to be_in tasks
      expect(task_cache.task_type).to eq (task.task_type)
      expect(task_cache.ecosystem).to eq @task_plan.owner.ecosystems.first
      expect(task_cache.student_ids).to match_array task.taskings.map { |tt| tt.role.student.id }
      expect(task_cache.student_names).to match_array(
        task.taskings.map { |tt| tt.role.student.name }
      )

      expect(task_cache.as_toc.deep_symbolize_keys).to match expected_unworked_toc

      expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
      expect(task_cache.due_at).to be_within(1).of(task.due_at)
      expect(task_cache.feedback_at).to be_nil
    end
  end

  it 'updates existing Tasks::TaskCaches for the given tasks' do
    task_caches = Tasks::Models::TaskCache.where(tasks_task_id: task_ids)
    expect(task_caches.count).to eq num_task_caches

    task_caches.each do |task_cache|
      task = task_cache.task
      expect(task).to be_in tasks
      expect(task_cache.task_type).to eq (task.task_type)
      expect(task_cache.ecosystem).to eq @task_plan.owner.ecosystems.first
      expect(task_cache.student_ids).to match_array task.taskings.map { |tt| tt.role.student.id }
      expect(task_cache.student_names).to match_array(
        task.taskings.map { |tt| tt.role.student.name }
      )

      expect(task_cache.as_toc.deep_symbolize_keys).to match expected_unworked_toc

      expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
      expect(task_cache.due_at).to be_within(1).of(task.due_at)
      expect(task_cache.feedback_at).to be_nil
    end

    first_task = student_tasks.first
    Preview::WorkTask.call(task: first_task, is_correct: true)

    expect { described_class.call(tasks: tasks) }.not_to change { Tasks::Models::TaskCache.count }

    task_caches.each do |task_cache|
      is_first_task = task_cache.reload.task == first_task

      task = task_cache.task
      expect(task).to be_in tasks
      expect(task_cache.task_type).to eq (task.task_type)
      expect(task_cache.ecosystem).to eq @task_plan.owner.ecosystems.first
      expect(task_cache.student_ids).to match_array task.taskings.map { |tt| tt.role.student.id }

      expect(task_cache.as_toc.deep_symbolize_keys).to match(
        is_first_task ? expected_worked_toc : expected_unworked_toc
      )

      expect(task_cache.opens_at).to be_within(1).of(task.opens_at)
      expect(task_cache.due_at).to be_within(1).of(task.due_at)
      expect(task_cache.feedback_at).to be_nil
    end
  end

  it 'is called when a task_plan is published' do
    expect(described_class).to receive(:perform_later) do |tasks:|
      expect(tasks).to match_array(@task_plan.reload.tasks)
    end

    DistributeTasks.call(task_plan: @task_plan)
  end

  it 'is called when a task step is updated' do
    task = @task_plan.tasks.first
    expect(described_class).to receive(:perform_later).with(tasks: task)

    tasked_exercise = task.tasked_exercises.first
    tasked_exercise.free_response = 'Something'
    tasked_exercise.save!
  end

  it 'is called when a task step is marked as completed' do
    task = @task_plan.tasks.first
    expect(described_class).to receive(:perform_later).with(tasks: task)

    task_step = task.task_steps.first
    MarkTaskStepCompleted.call(task_step: task_step)
  end

  it 'is called when placeholder steps are populated' do
    task = @task_plan.tasks.first
    # Queuing the background job 6 times is not ideal at all...
    # Might be fixed by moving to Rails 5 due to https://github.com/rails/rails/pull/19324
    expect(described_class).to receive(:perform_later).exactly(6).times.with(tasks: task)

    Tasks::PopulatePlaceholderSteps.call(task: task)
  end

  it 'is called when a new ecosystem is added to the course' do
    course = @task_plan.owner
    ecosystem = course.ecosystems.first
    course.course_ecosystems.delete_all :delete_all

    expect(described_class).to receive(:perform_later) do |tasks:|
      student_tasks = @task_plan.tasks.select do |task|
        task.taskings.any? { |tasking| tasking.role.student.present? }
      end
      expect(tasks).to match_array(student_tasks)
    end

    AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
  end
end
