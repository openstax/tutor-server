require 'rails_helper'

RSpec.describe Tasks::UpdateTaskPageCaches, type: :routine, speed: :slow do
  before(:all) { @task_plan = FactoryGirl.create :tasked_task_plan }

  let(:tasks)                { @task_plan.tasks }
  let(:task_ids)             { tasks.map(&:id) }
  let(:students)             { tasks.flat_map(&:taskings).map(&:role).map(&:student).compact }
  let(:num_students)         { students.size }
  let(:pages)                { tasks.flat_map(&:task_steps).select(&:exercise?).map(&:page).uniq }
  let(:num_pages)            { pages.size }
  let(:num_task_page_caches) { num_students * num_pages }

  it 'creates a Tasks::TaskPageCache for every student and every unique page with an exercise' do
    Tasks::Models::TaskPageCache.where(tasks_task_id: task_ids).delete_all

    expect { described_class.call(tasks: tasks) }
      .to change { Tasks::Models::TaskPageCache.count }.by(num_task_page_caches)

    task_page_caches = Tasks::Models::TaskPageCache.where(tasks_task_id: task_ids)
    task_page_caches.each do |task_page_cache|
      expect(task_page_cache.task).to be_in tasks
      expect(task_page_cache.student).to be_in students
      expect(task_page_cache.page).to be_in pages
      expect(task_page_cache.mapped_page).to be_in pages

      expect(task_page_cache.num_assigned_exercises).to eq 5 # 2 core + 3 personalized
      expect(task_page_cache.num_completed_exercises).to eq 0
      expect(task_page_cache.num_correct_exercises).to eq 0

      expect(task_page_cache.opens_at).to be_within(1).of(task_page_cache.task.opens_at)
      expect(task_page_cache.due_at).to be_within(1).of(task_page_cache.task.due_at)
      expect(task_page_cache.feedback_at).to be_nil
    end
  end

  it 'updates existing Tasks::TaskPageCaches' do
    task_page_caches = Tasks::Models::TaskPageCache.where(tasks_task_id: task_ids)
    expect(task_page_caches.count).to eq num_task_page_caches

    task_page_caches.each do |task_page_cache|
      expect(task_page_cache.task).to be_in tasks
      expect(task_page_cache.student).to be_in students
      expect(task_page_cache.page).to be_in pages
      expect(task_page_cache.mapped_page).to be_in pages

      expect(task_page_cache.num_assigned_exercises).to eq 5 # 2 core + 3 personalized
      expect(task_page_cache.num_completed_exercises).to eq 0
      expect(task_page_cache.num_correct_exercises).to eq 0

      expect(task_page_cache.opens_at).to be_within(1).of(task_page_cache.task.opens_at)
      expect(task_page_cache.due_at).to be_within(1).of(task_page_cache.task.due_at)
      expect(task_page_cache.feedback_at).to be_nil
    end

    first_task = tasks.first
    Preview::WorkTask.call(task: first_task, is_correct: true)

    expect { described_class.call(tasks: tasks) }
      .not_to change { Tasks::Models::TaskPageCache.count }

    task_page_caches.each do |task_page_cache|
      is_first_task = task_page_cache.reload.task == first_task

      expect(task_page_cache.task).to be_in tasks
      expect(task_page_cache.student).to be_in students
      expect(task_page_cache.page).to be_in pages
      expect(task_page_cache.mapped_page).to be_in pages

      expect(task_page_cache.num_assigned_exercises).to eq is_first_task ? 8 : 5
      expect(task_page_cache.num_completed_exercises).to eq is_first_task ? 8 : 0
      expect(task_page_cache.num_correct_exercises).to eq is_first_task ? 8 : 0
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
