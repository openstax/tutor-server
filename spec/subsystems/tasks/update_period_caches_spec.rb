require 'rails_helper'

RSpec.describe Tasks::UpdatePeriodCaches, type: :routine, speed: :medium do
  before(:all)                { @task_plan = FactoryBot.create :tasked_task_plan }

  let(:course)                { @task_plan.owner }
  let(:periods)               { course.periods.to_a }
  let(:period_ids)            { periods.map(&:id) }
  let(:first_period)          { periods.first }
  let(:first_task)            do
    @task_plan.tasks.find do |task|
      task.taskings.any? { |tasking| tasking.role.student.try!(:period) == first_period }
    end
  end
  let(:num_period_caches)     { periods.size }
  let(:ecosystem)             { course.ecosystems.first }
  let(:book)                  { ecosystem.books.first }
  let(:chapter)               { book.chapters.first }
  let(:page)                  { chapter.pages.first }
  let(:expected_unworked_toc) do
    {
      id: ecosystem.id,
      tutor_uuid: ecosystem.tutor_uuid,
      title: ecosystem.title,
      has_exercises: true,
      num_assigned_steps: 110,
      num_known_location_steps: 80,
      num_completed_steps: 0,
      num_assigned_exercises: 20,
      num_completed_exercises: 0,
      num_correct_exercises: 0,
      num_assigned_placeholders: 30,
      student_ids: [ kind_of(Integer) ] * 10,
      student_names: [ kind_of(String) ] * 10,
      books: [
        {
          id: book.id,
          tutor_uuid: book.tutor_uuid,
          title: book.title,
          has_exercises: true,
          num_assigned_steps: 80,
          num_completed_steps: 0,
          num_assigned_exercises: 20,
          num_completed_exercises: 0,
          num_correct_exercises: 0,
          num_assigned_placeholders: 30,
          student_ids: [ kind_of(Integer) ] * 10,
          student_names: [ kind_of(String) ] * 10,
          chapters: [
            {
              id: chapter.id,
              tutor_uuid: chapter.tutor_uuid,
              title: chapter.title,
              book_location: chapter.book_location,
              has_exercises: true,
              is_spaced_practice: false,
              num_assigned_steps: 80,
              num_completed_steps: 0,
              num_assigned_exercises: 20,
              num_completed_exercises: 0,
              num_correct_exercises: 0,
              num_assigned_placeholders: 30,
              student_ids: [ kind_of(Integer) ] * 10,
              student_names: [ kind_of(String) ] * 10,
              pages: [
                {
                  id: page.id,
                  tutor_uuid: page.tutor_uuid,
                  title: page.title,
                  book_location: page.book_location,
                  has_exercises: true,
                  is_spaced_practice: false,
                  num_assigned_steps: 80,
                  num_completed_steps: 0,
                  num_assigned_exercises: 20,
                  num_completed_exercises: 0,
                  num_correct_exercises: 0,
                  num_assigned_placeholders: 30,
                  student_ids: [ kind_of(Integer) ] * 10,
                  student_names: [ kind_of(String) ] * 10
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
      num_assigned_steps: 110,
      num_known_location_steps: 83,
      num_completed_steps: 11,
      num_assigned_exercises: 26,
      num_completed_exercises: 8,
      num_correct_exercises: 8,
      num_assigned_placeholders: 27,
      student_ids: [ kind_of(Integer) ] * 10,
      student_names: [ kind_of(String) ] * 10,
      books: [
        {
          id: book.id,
          tutor_uuid: book.tutor_uuid,
          title: book.title,
          has_exercises: true,
          num_assigned_steps: 83,
          num_completed_steps: 11,
          num_assigned_exercises: 26,
          num_completed_exercises: 8,
          num_correct_exercises: 8,
          num_assigned_placeholders: 27,
          student_ids: [ kind_of(Integer) ] * 10,
          student_names: [ kind_of(String) ] * 10,
          chapters: [
            {
              id: chapter.id,
              tutor_uuid: chapter.tutor_uuid,
              title: chapter.title,
              book_location: chapter.book_location,
              has_exercises: true,
              is_spaced_practice: false,
              num_assigned_steps: 83,
              num_completed_steps: 11,
              num_assigned_exercises: 26,
              num_completed_exercises: 8,
              num_correct_exercises: 8,
              num_assigned_placeholders: 27,
              student_ids: [ kind_of(Integer) ] * 10,
              student_names: [ kind_of(String) ] * 10,
              pages: [
                {
                  id: page.id,
                  tutor_uuid: page.tutor_uuid,
                  title: page.title,
                  book_location: page.book_location,
                  has_exercises: true,
                  is_spaced_practice: false,
                  num_assigned_steps: 83,
                  num_completed_steps: 11,
                  num_assigned_exercises: 26,
                  num_completed_exercises: 8,
                  num_correct_exercises: 8,
                  num_assigned_placeholders: 27,
                  student_ids: [ kind_of(Integer) ] * 10,
                  student_names: [ kind_of(String) ] * 10
                }
              ]
            }
          ]
        }
      ]
    }
  end

  it 'creates a Tasks::PeriodCache for the given tasks' do
    Tasks::Models::PeriodCache.where(course_membership_period_id: period_ids).delete_all

    expect { described_class.call(periods: periods, force: true) }
      .to change { Tasks::Models::PeriodCache.count }.by(num_period_caches)

    period_caches = Tasks::Models::PeriodCache.where(course_membership_period_id: period_ids)
    period_caches.each do |period_cache|
      period = period_cache.period
      expect(period).to be_in periods
      expect(period_cache.ecosystem).to eq course.ecosystems.first
      expect(period_cache.student_ids).to match_array period.students.map(&:id)

      expect(period_cache.as_toc.deep_symbolize_keys).to match expected_unworked_toc

      tasking_plan = period_cache.task_plan.tasking_plans.find { |tp| tp.target == period }
      expect(period_cache.opens_at).to be_within(1).of(tasking_plan.opens_at)
      expect(period_cache.due_at).to be_within(1).of(tasking_plan.due_at)
    end

    expect(
      Tasks::Models::TaskCache.where(
        tasks_task_id: @task_plan.tasks.map(&:id), is_cached_for_period: false
      ).exists?
    ).to eq false
  end

  it 'updates existing Tasks::PeriodCache for the given tasks' do
    period_caches = Tasks::Models::PeriodCache.where(course_membership_period_id: period_ids)
    expect(period_caches.count).to eq num_period_caches

    period_caches.each do |period_cache|
      period = period_cache.period
      expect(period).to be_in periods
      expect(period_cache.ecosystem).to eq course.ecosystems.first
      expect(period_cache.student_ids).to match_array period.students.map(&:id)

      expect(period_cache.as_toc.deep_symbolize_keys).to match expected_unworked_toc

      tasking_plan = period_cache.task_plan.tasking_plans.find { |tp| tp.target == period }
      expect(period_cache.opens_at).to be_within(1).of(tasking_plan.opens_at)
      expect(period_cache.due_at).to be_within(1).of(tasking_plan.due_at)
    end

    expect(
      Tasks::Models::TaskCache.where(
        tasks_task_id: @task_plan.tasks.map(&:id), is_cached_for_period: false
      ).exists?
    ).to eq false

    Preview::WorkTask.call(task: first_task, is_correct: true)

    expect(
      Tasks::Models::TaskCache.where(
        tasks_task_id: @task_plan.tasks.map(&:id), is_cached_for_period: false
      ).exists?
    ).to eq false

    expect { described_class.call(periods: periods, force: true) }.not_to(
      change { Tasks::Models::PeriodCache.count }
    )

    period_caches.reload.each do |period_cache|
      period = period_cache.period
      is_first_period = period == first_period

      expect(period).to be_in periods
      expect(period_cache.ecosystem).to eq course.ecosystems.first
      expect(period_cache.student_ids).to match_array period.students.map(&:id)

      expect(period_cache.as_toc.deep_symbolize_keys).to match(
        is_first_period ? expected_worked_toc : expected_unworked_toc
      )

      tasking_plan = period_cache.task_plan.tasking_plans.find { |tp| tp.target == period }
      expect(period_cache.opens_at).to be_within(1).of(tasking_plan.opens_at)
      expect(period_cache.due_at).to be_within(1).of(tasking_plan.due_at)
    end

    expect(
      Tasks::Models::TaskCache.where(
        tasks_task_id: @task_plan.tasks.map(&:id), is_cached_for_period: false
      ).exists?
    ).to eq false
  end

  it 'is called when a task_plan is published' do
    expect(described_class).to receive(:perform_later) do |periods:|
      expect(periods).to match_array(@task_plan.tasking_plans.map(&:target))
    end

    DistributeTasks.call(task_plan: @task_plan)
  end

  it 'is called when a task step is updated' do
    expect(described_class).to receive(:perform_later).with(periods: [ first_period ])

    tasked_exercise = first_task.tasked_exercises.first
    tasked_exercise.free_response = 'Something'
    tasked_exercise.save!
  end

  it 'is called when a task step is marked as completed' do
    expect(described_class).to receive(:perform_later).with(periods: [ first_period ])

    task_step = first_task.task_steps.first
    MarkTaskStepCompleted.call(task_step: task_step)
  end

  it 'is called when placeholder steps are populated' do
    # Queuing the background job 6 times is not ideal at all...
    # Might be fixed by moving to Rails 5 due to https://github.com/rails/rails/pull/19324
    expect(described_class).to receive(:perform_later).exactly(6).with(periods: [ first_period ])

    Tasks::PopulatePlaceholderSteps.call(task: first_task)
  end

  it 'is called when a new ecosystem is added to the course' do
    ecosystem = course.ecosystems.first
    course.course_ecosystems.delete_all :delete_all

    expect(described_class).to receive(:perform_later) do |periods:|
      expect(periods).to match_array course.periods
    end

    AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
  end

  it 'is called when a new student joins the period' do
    student_user = FactoryBot.create :user_profile

    expect(described_class).to receive(:perform_later) do |periods:|
      expect(periods).to eq [ first_period ]
    end

    AddUserAsPeriodStudent.call(user: student_user, period: first_period)
  end

  it 'is called with force: true when a student is dropped' do
    student = first_period.students.first

    expect(described_class).to receive(:perform_later) do |periods:, force:|
      expect(periods).to eq first_period
      expect(force).to eq true
    end

    CourseMembership::InactivateStudent.call(student: student)
  end

  it 'is called with force: true when a student is reactivated' do
    student = first_period.students.first
    CourseMembership::InactivateStudent.call(student: student)

    expect(described_class).to receive(:perform_later) do |periods:, force:|
      expect(periods).to eq first_period
      expect(force).to eq true
    end

    CourseMembership::ActivateStudent.call(student: student)
  end
end
