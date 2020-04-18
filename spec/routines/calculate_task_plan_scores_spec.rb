require 'rails_helper'
require 'vcr_helper'

RSpec.describe CalculateTaskPlanScores, type: :routine, vcr: VCR_OPTS, speed: :slow do
  before(:all) do
    @number_of_students = 8

    begin
      RSpec::Mocks.setup

      reading = FactoryBot.create :tasked_task_plan, number_of_students: @number_of_students
      course = reading.owner
      reading_pages = Content::Models::Page.where(id: reading.settings['page_ids'])

      @task_plan = FactoryBot.create(
        :tasks_task_plan,
        type: :homework,
        owner: course,
        assistant_code_class_name: 'Tasks::Assistants::HomeworkAssistant',
        target: course.periods.first,
        settings: {
          page_ids: reading_pages.map(&:id).map(&:to_s),
          exercises: reading_pages.first.exercises.first(5).map do |exercise|
            { id: exercise.id.to_s, points: [ 1.0 ] * exercise.num_questions }
          end,
          exercises_count_dynamic: 3
        }
      )
      @tasking_plan = @task_plan.tasking_plans.first
      @period = @task_plan.owner.periods.first
      @period_2 = FactoryBot.create :course_membership_period, course: @period.course
      @tasking_plan_2 = FactoryBot.create(
        :tasks_tasking_plan,
        task_plan: @task_plan,
        target: @period_2,
        opens_at: Time.current - 1.day,
        due_at: Time.current - 1.day
      )
      DistributeTasks.call task_plan: @task_plan
    ensure
      RSpec::Mocks.teardown
    end
  end

  # Workaround for PostgreSQL bug where the task records
  # stop existing in SELECT ... FOR UPDATE queries (but not in regular SELECTs)
  # after the transaction rollback that happens in-between spec examples
  before(:each)       { @task_plan.tasks.each(&:touch).each(&:reload) }

  let(:tasking_plans) { [ @tasking_plan, @tasking_plan_2 ].sort_by { |tp| tp.target.name } }
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
      scores.each_with_index do |tasking_plan_output, index|
        tasking_plan = tasking_plans[index]
        period = tasking_plan.target

        expect(tasking_plan_output.id).to eq tasking_plan.id
        expect(tasking_plan_output.period_id).to eq period.id
        expect(tasking_plan_output.period_name).to eq period.name
        expect(tasking_plan_output.question_headings.map(&:symbolize_keys)).to eq(
          tasks.first.task_steps.each_with_index.map do |task_step, index|
            {
              title: "Q#{index + 1}",
              points: 1.0,
              type: task_step.is_core? ? 'MCQ' : 'Tutor',
              question_id: task_step.is_core? ? task_step.tasked.question_id : nil,
              exercise_id: task_step.is_core? ? task_step.tasked.content_exercise_id : nil
            }
          end
        )
        expect(tasking_plan_output.late_work_fraction_penalty).to eq late_work_penalty
        expect(tasking_plan_output.num_questions_dropped).to eq 0
        expect(tasking_plan_output.points_dropped).to eq 0.0
        expect(tasking_plan_output.questions_need_grading).to eq false
        expect(tasking_plan_output.grades_need_publishing).to eq false

        expect(tasking_plan_output.students.map(&:deep_symbolize_keys)).to eq(
          tasks.map do |task|
            student = task.taskings.first.role.student

            {
              role_id: task.taskings.first.entity_role_id,
              available_points: 8.0,
              late_work_fraction_penalty: task.late_work_penalty,
              first_name: student.first_name,
              last_name: student.last_name,
              late_work_point_penalty: 0.0,
              is_dropped: false,
              is_late: task.late?,
              student_identifier: student.student_identifier,
              total_fraction: nil,
              total_points: 0.0,
              questions: task.task_steps.map do |ts|
                if ts.exercise?
                  {
                    id: ts.tasked.question_id,
                    exercise_id: ts.tasked.content_exercise_id,
                    is_completed: false,
                    selected_answer_id: ts.tasked.answer_id,
                    points: ts.completed? || task.past_due? ? 0.0 : nil,
                    free_response: nil,
                    grader_points: nil,
                    grader_comments: nil,
                    needs_grading: false
                  }
                else
                  {
                    is_completed: false,
                    points: task.past_due? ? 0.0 : nil,
                    needs_grading: false
                  }
                end
              end.compact,
              questions_need_grading: false,
              grades_need_publishing: false
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

      scores.each_with_index do |tasking_plan_output, index|
        tasking_plan = tasking_plans[index]
        period = tasking_plan.target

        expect(tasking_plan_output.id).to eq tasking_plan.id
        expect(tasking_plan_output.period_id).to eq period.id
        expect(tasking_plan_output.period_name).to eq period.name
        expect(tasking_plan_output.question_headings.map(&:symbolize_keys)).to eq(
          tasks.first.task_steps.each_with_index.map do |task_step, index|
            {
              title: "Q#{index + 1}",
              points: 1.0,
              type: task_step.is_core? ? 'MCQ' : 'Tutor',
              question_id: task_step.is_core? ? task_step.tasked.question_id : nil,
              exercise_id: task_step.is_core? ? task_step.tasked.content_exercise_id : nil,
            }
          end
        )
        expect(tasking_plan_output.late_work_fraction_penalty).to eq late_work_penalty
        expect(tasking_plan_output.num_questions_dropped).to eq 0
        expect(tasking_plan_output.points_dropped).to eq 0.0
        expect(tasking_plan_output.questions_need_grading).to eq false
        expect(tasking_plan_output.grades_need_publishing).to eq false

        expect(tasking_plan_output.students.map(&:deep_symbolize_keys)).to eq(
          tasks.map do |task|
            student = task.taskings.first.role.student

            {
              role_id: task.taskings.first.entity_role_id,
              available_points: 8.0,
              late_work_fraction_penalty: task.late_work_penalty,
              first_name: student.first_name,
              last_name: student.last_name,
              late_work_point_penalty: 0.0,
              is_dropped: false,
              is_late: task.late?,
              student_identifier: student.student_identifier,
              total_fraction: task.started? ? 0.0 : nil,
              total_points: 0.0,
              questions: task.task_steps.map do |ts|
                if ts.exercise?
                  {
                    id: ts.tasked.question_id,
                    exercise_id: ts.tasked.content_exercise_id,
                    is_completed: ts.completed?,
                    selected_answer_id: ts.tasked.answer_id,
                    points: ts.completed? || task.past_due? ? 0.0 : nil,
                    free_response: ts.tasked.free_response,
                    grader_points: nil,
                    grader_comments: nil,
                    needs_grading: false
                  }
                else
                  {
                    is_completed: false,
                    points: task.past_due? ? 0.0 : nil,
                    needs_grading: false
                  }
                end
              end.compact,
              questions_need_grading: false,
              grades_need_publishing: false
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

      scores.each_with_index do |tasking_plan_output, index|
        tasking_plan = tasking_plans[index]
        period = tasking_plan.target

        expect(tasking_plan_output.id).to eq tasking_plan.id
        expect(tasking_plan_output.period_id).to eq period.id
        expect(tasking_plan_output.period_name).to eq period.name
        expect(tasking_plan_output.question_headings.map(&:symbolize_keys)).to eq(
          tasks.first.task_steps.each_with_index.map do |task_step, index|
            {
              title: "Q#{index + 1}",
              points: 1.0,
              type: task_step.is_core? ? 'MCQ' : 'Tutor',
              question_id: task_step.is_core? ? task_step.tasked.question_id : nil,
              exercise_id: task_step.is_core? ? task_step.tasked.content_exercise_id : nil
            }
          end
        )
        expect(tasking_plan_output.late_work_fraction_penalty).to eq late_work_penalty
        expect(tasking_plan_output.num_questions_dropped).to eq 0
        expect(tasking_plan_output.points_dropped).to eq 0.0
        expect(tasking_plan_output.questions_need_grading).to eq false
        expect(tasking_plan_output.grades_need_publishing).to eq false

        expect(tasking_plan_output.students.map(&:deep_symbolize_keys)).to eq(
          tasks.each_with_index.map do |task, index|
            student = task.taskings.first.role.student
            is_correct = [ 0, 2, 3 ].include?(index)

            {
              role_id: task.taskings.first.entity_role_id,
              available_points: 8.0,
              late_work_fraction_penalty: task.late_work_penalty,
              first_name: student.first_name,
              last_name: student.last_name,
              late_work_point_penalty: is_correct ? 8.0 * task.late_work_penalty : 0.0,
              is_dropped: false,
              is_late: task.late?,
              student_identifier: student.student_identifier,
              total_fraction: is_correct ? task.late_work_multiplier : task.started? ? 0.0 : nil,
              total_points: is_correct ? 8.0 * task.late_work_multiplier : 0.0,
              questions: task.task_steps.map do |ts|
                if ts.exercise?
                  {
                    id: ts.tasked.question_id,
                    exercise_id: ts.tasked.content_exercise_id,
                    is_completed: ts.completed?,
                    selected_answer_id: ts.tasked.answer_id,
                    points: ts.completed? || task.past_due? ? (is_correct ? 1.0 : 0.0) : nil,
                    free_response: ts.tasked.free_response,
                    grader_points: nil,
                    grader_comments: nil,
                    needs_grading: false
                  }
                else
                  {
                    is_completed: false,
                    points: task.past_due? ? 0.0 : nil,
                    needs_grading: false
                  }
                end
              end.compact,
              questions_need_grading: false,
              grades_need_publishing: false
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
