require 'rails_helper'
require 'vcr_helper'

RSpec.describe CalculateTaskStats, type: :routine, vcr: VCR_OPTS, speed: :slow do
  before(:all) do
    @number_of_students = 8

    begin
      RSpec::Mocks.setup

      @task_plan = FactoryBot.create :tasked_task_plan, number_of_students: @number_of_students
      @period = @task_plan.course.periods.first
    ensure
      RSpec::Mocks.teardown
    end
  end

  before do
    @task_plan.reload
    @period.reload
  end

  let(:student_tasks) do
    @task_plan.tasks.joins(taskings: { role: :student }).preload(
      taskings: { role: :profile }
    ).to_a
  end

  context 'with an unworked plan' do
    let(:stats) { described_class.call(tasks: @task_plan.tasks).outputs.stats }

    it 'is all nil or zero for an unworked task_plan' do
      expect(stats.first.total_count).to eq student_tasks.length
      expect(stats.first.complete_count).to eq 0
      expect(stats.first.partially_complete_count).to eq 0
    end

    it 'does not break if an exercise has more than one tag' do
      cnx_page_hashes = [
        { id: 'e26d1433-f8e4-41db-a757-0e061d6d2737', title: 'Prokaryotic Cells' }
      ]

      cnx_chapter_hashes = [
        { title: 'Prokaryotic Cells', contents: cnx_page_hashes }
      ]

      cnx_unit_hashes = [
        { title: 'Unit 2', contents: cnx_chapter_hashes }
      ]

      cnx_book_hash = {
        id: '6c322e32-9fb0-4c4d-a1d7-20c95c5c7af2',
        version: '22.1',
        title: 'Biology for AP® Courses',
        tree: {
          id: '6c322e32-9fb0-4c4d-a1d7-20c95c5c7af2@22.1',
          title: 'Biology for AP® Courses',
          contents: cnx_chapter_hashes
        }
      }

      cnx_book = OpenStax::Cnx::V1::Book.new hash: cnx_book_hash.deep_stringify_keys

      @ecosystem = FactoryBot.create :content_ecosystem

      reading_processing_instructions = FactoryBot.build(
        :content_book
      ).reading_processing_instructions

      @book = Content::ImportBook.call(
        cnx_book: cnx_book,
        ecosystem: @ecosystem,
        reading_processing_instructions: reading_processing_instructions
      ).outputs.book

      course = FactoryBot.create :course_profile_course, :with_assistants
      AddEcosystemToCourse[course: course, ecosystem: @ecosystem]

      period = FactoryBot.create :course_membership_period, course: course
      student = FactoryBot.create(:user_profile)
      AddUserAsPeriodStudent.call(user: student, period: period)

      task_plan = FactoryBot.create(
        :tasks_task_plan,
        course: course,
        ecosystem: @ecosystem,
        settings: { 'page_ids' => [ @book.pages.first.id.to_s ] },
        assistant: get_assistant(course: course, task_plan_type: 'reading')
      )

      DistributeTasks.call(task_plan: task_plan)

      expect(stats.first.complete_count).to eq 0
    end
  end

  context 'after task steps are marked as completed' do
    it 'records partial/complete status' do
      first_task = student_tasks.first
      step = first_task.task_steps.find_by(tasked_type: 'Tasks::Models::TaskedReading')
      MarkTaskStepCompleted[task_step: step]
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

      expect(stats.first.complete_count).to eq 0
      expect(stats.first.partially_complete_count).to eq 1

      work_task(task: first_task, is_correct: false)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

      expect(stats.first.complete_count).to eq 1
      expect(stats.first.partially_complete_count).to eq 0

      last_task = student_tasks.last
      MarkTaskStepCompleted[task_step: last_task.task_steps.first]
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.complete_count).to eq 1
      expect(stats.first.partially_complete_count).to eq 1
    end
  end

  context 'after task steps are marked as correct or incorrect' do
    it 'records them' do
      work_task(task: student_tasks[0], is_correct: true)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

      expect(stats.first.complete_count).to eq 1
      expect(stats.first.partially_complete_count).to eq 0

      work_task(task: student_tasks[1], is_correct: false)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.complete_count).to eq 2
      expect(stats.first.partially_complete_count).to eq 0

      work_task(task: student_tasks[2], is_correct: true)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.complete_count).to eq 3
      expect(stats.first.partially_complete_count).to eq 0

      work_task(task: student_tasks[3], is_correct: true)
      stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats
      expect(stats.first.complete_count).to eq 4
      expect(stats.first.partially_complete_count).to eq 0
    end
  end

  context 'with multiple course periods' do
    let(:course)   { @task_plan.course }
    let(:period_2) { FactoryBot.create :course_membership_period, course: course }
    let(:stats)    { described_class.call(tasks: @task_plan.tasks).outputs.stats }

    before do
      student_tasks.last(@number_of_students/2).each do |task|
        task.taskings.each do |tasking|
          ::MoveStudent.call(period: period_2, student: tasking.role.student)
        end
      end
    end

    it 'splits the students into their periods' do
      expect(stats.first.total_count).to eq student_tasks.length/2
      expect(stats.first.complete_count).to eq 0
      expect(stats.first.partially_complete_count).to eq 0

      expect(stats.second.total_count).to eq student_tasks.length/2
      expect(stats.second.complete_count).to eq 0
      expect(stats.second.partially_complete_count).to eq 0
    end

    context 'if a period was archived after the assignment was distributed' do
      before { period_2.destroy }

      it 'does not show the archived period' do
        expect(stats.first.total_count).to eq student_tasks.length/2
        expect(stats.first.complete_count).to eq 0
        expect(stats.first.partially_complete_count).to eq 0

        expect(stats.second).to be_nil
      end
    end

    context 'if the students were dropped after working the assignment' do
      it 'does not show dropped students' do
        first_task = student_tasks.first
        work_task(task: first_task, is_correct: true)

        stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

        expect(stats.first.complete_count).to eq 1
        expect(stats.first.partially_complete_count).to eq 0

        first_task.taskings.first.role.student.destroy!

        stats = described_class.call(tasks: @task_plan.reload.tasks).outputs.stats

        expect(stats.first.total_count).to eq student_tasks.length/2 - 1
        expect(stats.first.complete_count).to eq 0
        expect(stats.first.partially_complete_count).to eq 0

        expect(stats.second.total_count).to eq student_tasks.length/2
        expect(stats.second.complete_count).to eq 0
        expect(stats.second.partially_complete_count).to eq 0
      end
    end
  end

  protected

  def work_task(task:, is_correct:, num_steps: nil)
    is_completed = num_steps.nil? ? true : ->(task_step, index) { index < num_steps }
    Preview::WorkTask[task: task, is_completed: is_completed, is_correct: is_correct]
  end

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.find_by(tasks_task_plan_type: task_plan_type).assistant
  end

  def answer_ids(exercise_content, question_index)
    JSON.parse(exercise_content)['questions'][question_index]['answers'].map{|aa| aa['id'].to_s}
  end
end
