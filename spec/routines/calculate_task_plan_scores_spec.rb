require 'rails_helper'
require 'vcr_helper'

RSpec.describe CalculateTaskPlanScores, type: :routine, vcr: VCR_OPTS, speed: :slow do
  before(:all) do
    @number_of_students = 8

    begin
      RSpec::Mocks.setup

      @task_plan = FactoryBot.create :tasked_task_plan, number_of_students: @number_of_students
      @period = @task_plan.owner.periods.first
      @period_2 = FactoryBot.create :course_membership_period, course: @period.course
      FactoryBot.create :tasks_tasking_plan, task_plan: @task_plan, target: @period_2
      DistributeTasks.call task_plan: @task_plan
    ensure
      RSpec::Mocks.teardown
    end
  end

  # Workaround for PostgreSQL bug where the task records
  # stop existing in SELECT ... FOR UPDATE queries (but not in regular SELECTs)
  # after the transaction rollback that happens in-between spec examples
  before(:each)       { @task_plan.tasks.each(&:touch).each(&:reload) }

  let(:periods)       { [ @period, @period_2 ].sort_by(&:name) }
  let(:tasks)         do
    @task_plan.tasks.joins(
      taskings: { role: :student }
    ).preload(taskings: { role: :student}).sort_by do |task|
      student = task.taskings.first.role.student

      [ student.last_name, student.first_name ]
    end
  end
  let(:late_work_penalty) { @task_plan.grading_template.late_work_penalty }

  subject(:scores) { described_class.call(task_plan: @task_plan).outputs.scores }

  context 'with an unworked plan' do
    it 'shows available points but no scores' do
      scores.each_with_index do |period_output, index|
        period = periods[index]

        expect(period_output.id).to eq period.id
        expect(period_output.name).to eq period.name
        expect(period_output.question_headings.map(&:symbolize_keys)).to eq(
          8.times.map { |idx| { title: "Q#{idx + 1}", points: 1.0, type: idx < 5 ? 'MCQ' : 'Tutor' } }
        )
        expect(period_output.late_work_fraction_penalty).to eq late_work_penalty
        expect(period_output.num_questions_dropped).to eq 0
        expect(period_output.points_dropped).to eq 0.0

        expect(period_output.students.map(&:deep_symbolize_keys)).to eq(
          tasks.map do |task|
            student = task.taskings.first.role.student
            {
               role_id: task.taskings.first.entity_role_id,
               available_points: 8.0,
               late_work_fraction_penalty: late_work_penalty,
               first_name: student.first_name,
               last_name: student.last_name,
               late_work_point_penalty: 0.0,
               is_dropped: false,
               is_late: false,
               student_identifier: student.student_identifier,
               total_fraction: 0.0,
               total_points: 0.0,
               questions: tasks[0].task_steps.map do |ts|
                 if ts.exercise?
                   {
                    id: ts.tasked.question_id,
                    exercise_id: ts.tasked.content_exercise_id,
                    is_completed: false,
                    selected_answer_id: ts.tasked.answer_id,
                    points: 0.0,
                    free_response: nil,
                   }
                 elsif ts.placeholder?
                   {
                    is_completed: false,
                    points: ts.task.late? ? 0.0 : nil
                   }
                 end
               end.compact
            }
          end
        )
      end
    end
  end

  context 'after task steps are marked as completed' do
    it 'shows available points and assignment scores' do
      work_task(task: tasks.first, is_correct: false)

      Preview::AnswerExercise.call(
        task_step: tasks.second.task_steps.select(&:exercise?).first, is_correct: false
      )

      scores.each_with_index do |period_output, index|
        period = periods[index]

        expect(period_output.id).to eq period.id
        expect(period_output.name).to eq period.name
        expect(period_output.question_headings.map(&:symbolize_keys)).to eq(
          8.times.map { |idx| { title: "Q#{idx + 1}", points: 1.0, type: idx < 5 ? 'MCQ' : 'Tutor' } }
        )
        expect(period_output.late_work_fraction_penalty).to eq late_work_penalty
        expect(period_output.num_questions_dropped).to eq 0
        expect(period_output.points_dropped).to eq 0.0

        expect(period_output.students[0..0].map(&:deep_symbolize_keys)).to eq(
          tasks[0..0].map do |task|
            student = task.taskings.first.role.student
            {
              role_id: task.taskings.first.entity_role_id,
              available_points: 8.0,
              late_work_fraction_penalty: late_work_penalty,
              first_name: student.first_name,
              last_name: student.last_name,
              late_work_point_penalty: 0.0,
              is_dropped: false,
              is_late: false,
              student_identifier: student.student_identifier,
              total_fraction: 0.0,
              total_points: 0.0,
              questions: tasks[0].task_steps.map do |ts|
                if ts.exercise?
                  {
                   id: ts.tasked.question_id,
                   exercise_id: ts.tasked.content_exercise_id,
                   is_completed: ts.completed?,
                   selected_answer_id: ts.tasked.answer_id,
                   points: 0.0,
                   free_response: ts.tasked.free_response,
                  }
                elsif ts.placeholder?
                  {
                   is_completed: false,
                   points: ts.task.late? ? 0.0 : nil
                  }
                end
              end.compact
            }
          end
        )
      end
    end
  end

  context 'after task steps are marked as correct or incorrect' do
    it 'shows available points and assignment scores' do
      work_task(task: tasks.first, is_correct: true)
      work_task(task: tasks.second, is_correct: false)
      work_task(task: tasks.third, is_correct: true)
      work_task(task: tasks.fourth, is_correct: true)

      scores.each_with_index do |period_output, index|
        period = periods[index]

        expect(period_output.id).to eq period.id
        expect(period_output.name).to eq period.name
        expect(period_output.question_headings.map(&:symbolize_keys)).to eq(
          8.times.map { |idx| { title: "Q#{idx + 1}", points: 1.0, type: idx < 5 ? 'MCQ' : 'Tutor' } }
        )
        expect(period_output.late_work_fraction_penalty).to eq late_work_penalty
        expect(period_output.num_questions_dropped).to eq 0
        expect(period_output.points_dropped).to eq 0.0

        expect(period_output.students[0..0].map(&:deep_symbolize_keys)).to eq(
          tasks[0..0].each_with_index.map do |task, index|
            student = task.taskings.first.role.student
            points = [ 0, 2, 3 ].include?(index) ? 1.0 : 0.0
            {
              role_id: task.taskings.first.entity_role_id,
              available_points: 8.0,
              late_work_fraction_penalty: late_work_penalty,
              first_name: student.first_name,
              last_name: student.last_name,
              late_work_point_penalty: 8.0 * late_work_penalty * points,
              is_dropped: false,
              is_late: false,
              student_identifier: student.student_identifier,
              total_fraction: 0.5,
              total_points: 4.0,
              questions: tasks[0].task_steps.map do |ts|
                if ts.exercise?
                  {
                   id: ts.tasked.question_id,
                   exercise_id: ts.tasked.content_exercise_id,
                   is_completed: ts.completed?,
                   selected_answer_id: ts.tasked.answer_id,
                   points: points,
                   free_response: ts.tasked.free_response,
                  }
                elsif ts.placeholder?
                  {
                   is_completed: false,
                   points: ts.task.late? ? 0.0 : nil
                  }
                end
              end.compact
            }
          end
        )
      end
    end
  end

  protected

  def work_task(task:, is_correct:, num_steps: nil)
    is_completed = num_steps.nil? ? true : ->(task_step, index) { index < num_steps }
    Preview::WorkTask[task: task, is_completed: is_completed, is_correct: is_correct]
  end
end
