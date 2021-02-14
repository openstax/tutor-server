require 'rails_helper'
require 'vcr_helper'

RSpec.describe CalculateTaskPlanScores, type: :routine, vcr: VCR_OPTS, speed: :slow do
  before(:all) { DatabaseCleaner.clean }

  let(:ecosystem) { generate_mini_ecosystem }
  let(:book) { ecosystem.books.first }
  let(:offering) { FactoryBot.create :catalog_offering, ecosystem: ecosystem }
  let(:course) {
    FactoryBot.create :course_profile_course, :with_grading_templates,
      offering: offering, is_preview: true
  }
  let(:reading_pages) { book.pages[0..2] }
  let(:homework_pages) { book.pages[0..2] }
  let(:number_of_students) { 8 }
  let(:reading_task_plan) {
    FactoryBot.create :tasked_task_plan,
      type: :reading,
      number_of_students: number_of_students,
      course: course,
      ecosystem: ecosystem
  }
  let(:homework_task_plan) {
    FactoryBot.create :tasked_task_plan,
      type: :homework,
      ecosystem: ecosystem,
      course: course,
      number_of_students: number_of_students,
      target: course.periods.first
      # settings: {
      #   page_ids: homework_pages.map(&:id).map(&:to_s),
      #   exercises: homework_pages.first.exercises.first(5).map do |exercise|
      #     { id: exercise.id.to_s, points: [ 1.0 ] * exercise.number_of_questions }
      #   end,
      #   exercises_count_dynamic: 3
      # }
  }

  let(:external_task_plan) {
    FactoryBot.create(
      :tasked_task_plan,
      type: :external,
      ecosystem: ecosystem,
      course: course,
      assistant: FactoryBot.create(
        :tasks_assistant, code_class_name: 'Tasks::Assistants::ExternalAssignmentAssistant',
      ),
      target: course.periods.first,
      settings: { external_url: 'https://www.example.com' }
    )
  }

  before(:each) {
    task_plan.tasks.each(&:touch).each(&:reload)
  }

  let(:tasking_plans) { task_plan.tasking_plans.sort_by { |tp| tp.target.name } }
  let(:tasks) do
    task_plan.tasks.joins(
      taskings: { role: :student }
    ).preload(taskings: { role: :student }).sort_by do |task|
      student = task.taskings.first.role.student
      [student.last_name, student.first_name]
    end
  end

  let(:late_work_penalty) { task_plan.late_work_penalty }

  subject(:scores) { described_class.call(task_plan: task_plan).outputs.scores }

  context 'homework' do
    let(:task_plan) { homework_task_plan }
    before(:each) {
      spaced_page = FactoryBot.create :content_page, book: book
      homework_pages[0].exercises.each do |exercise|
        FactoryBot.create :content_exercise, page: spaced_page, group_uuid: exercise.group_uuid
      end
    }
    context 'with an unworked plan' do
      it 'shows available points but no total points/scores' do
        scores.each_with_index do |tasking_plan_output, index|
          tasking_plan = tasking_plans[index]
          period = tasking_plan.target

          expect(tasking_plan_output.id).to eq tasking_plan.id
          expect(tasking_plan_output.period_id).to eq period.id
          expect(tasking_plan_output.period_name).to eq period.name

          expected_headings = tasks.first.task_steps.each_with_index.map do |task_step, index|
              title = "Q#{index + 1}"
              points_without_dropping = 1.0
              points = 1.0

              if task_step.fixed_group? && task_step.exercise?
                a_hash_including(
                  title: title,
                  points_without_dropping: points_without_dropping,
                  points: points,
                  type: 'MCQ',
                  question_id: task_step.tasked.question_id,
                  exercise_id: task_step.tasked.content_exercise_id
                )
              else
                a_hash_including(
                  title: title,
                  points_without_dropping: points_without_dropping,
                  points: points,
                  type: 'Tutor'
                )
              end

          end
          expect(tasking_plan_output.question_headings.map(&:symbolize_keys)).to(
            match a_collection_including(*expected_headings)
          )
          expect(tasking_plan_output.late_work_fraction_penalty).to eq late_work_penalty
          expect(tasking_plan_output.num_questions_dropped).to eq 0
          expect(tasking_plan_output.points_dropped).to eq 0.0
          expect(tasking_plan_output.total_fraction).to be_nil
          expect(tasking_plan_output.gradable_step_count).to eq 0
          expect(tasking_plan_output.ungraded_step_count).to eq 0
          expect(tasking_plan_output.grades_need_publishing).to eq false

          available_points = tasking_plan_output.question_headings.sum{ |h| h.points_without_dropping }

          expect(tasking_plan_output.students.map(&:deep_symbolize_keys)).to eq(
            tasks.map do |task|
              student = task.taskings.first.role.student

              {
                role_id: task.taskings.first.entity_role_id,
                task_id: task.id,
                available_points: available_points,
                first_name: student.first_name,
                last_name: student.last_name,
                late_work_point_penalty: 0.0,
                is_dropped: false,
                is_late: task.late?,
                student_identifier: student.student_identifier,
                total_fraction: nil,
                total_points: nil,
                questions: task.task_steps.map do |ts|
                  if ts.exercise?
                    tasked = ts.tasked

                    {
                      task_step_id: ts.id,
                      exercise_id: tasked.content_exercise_id,
                      question_id: tasked.question_id,
                      is_completed: false,
                      is_correct: false,
                      selected_answer_id: tasked.answer_id,
                      points: ts.completed? || task.past_due? ? 0.0 : nil,
                      late_work_point_penalty: 0.0,
                      free_response: nil,
                      grader_points: nil,
                      grader_comments: nil,
                      needs_grading: false,
                      submitted_late: false
                    }
                  else
                    {
                      task_step_id: ts.id,
                      is_completed: false,
                      points: task.past_due? ? 0.0 : nil,
                      needs_grading: false
                    }
                  end
                end,
                grades_need_publishing: false
              }
            end
          )
        end
      end
    end

    context 'after task steps are marked as completed' do
      let(:task_plan) { homework_task_plan }

      it 'shows available points and total points/scores' do
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
          headings = tasking_plan_output.question_headings.map(&:symbolize_keys)
          expected_headings = tasks.second.task_steps.each_with_index.map do |task_step, index|
            title = "Q#{index + 1}"
            points_without_dropping = 1.0
            points = 1.0

            if task_step.fixed_group? && task_step.exercise?
              a_hash_including(
                title: title,
                points_without_dropping: points_without_dropping,
                points: points,
                type: 'MCQ',
                question_id: task_step.tasked.question_id,
                exercise_id: task_step.tasked.content_exercise_id
              )
            else
              a_hash_including(
                title: title,
                points_without_dropping: points_without_dropping,
                points: points,
                type: 'Tutor'
              )
            end
          end.compact
          # TODO: figure out why this fails on CI but not locally
          # expect(headings).to match a_collection_including(*expected_headings)
          expect(tasking_plan_output.late_work_fraction_penalty).to eq late_work_penalty
          expect(tasking_plan_output.num_questions_dropped).to eq 0
          expect(tasking_plan_output.points_dropped).to eq 0.0
          fractions_array = tasks.map(&:score).compact
          expect(tasking_plan_output.total_fraction).to eq(
            fractions_array.sum(0.0)/fractions_array.size
          )
          expect(tasking_plan_output.gradable_step_count).to eq 0
          expect(tasking_plan_output.ungraded_step_count).to eq 0
          grades_need_publishing = task_plan.grading_template.auto_grading_feedback_on_publish?
          expect(tasking_plan_output.grades_need_publishing).to eq grades_need_publishing

          available_points = tasking_plan_output.question_headings.sum{ |h| h.points_without_dropping }

          expected_headings = tasks.each_with_index.map do |task, index|
            student = task.taskings.first.role.student
            is_worked = index < 2

            a_hash_including({
              role_id: task.taskings.first.entity_role_id,
              task_id: task.id,
              available_points: available_points,
              first_name: student.first_name,
              last_name: student.last_name,
              late_work_point_penalty: 0.0,
              is_dropped: false,
              is_late: task.late?,
              student_identifier: student.student_identifier,
              total_fraction: task.score,
              total_points: task.points,
              grades_need_publishing: grades_need_publishing && is_worked,
              questions: task.task_steps.map do |ts|
                if ts.exercise?
                  tasked = ts.tasked
                  {
                    task_step_id: ts.id,
                    exercise_id: tasked.content_exercise_id,
                    question_id: tasked.question_id,
                    is_completed: ts.completed?,
                    is_correct: ts.is_correct?,
                    selected_answer_id: tasked.answer_id,
                    points: ts.completed? ? task.completion_weight : (task.past_due? ? 0.0 : nil),
                    late_work_point_penalty: 0.0,
                    free_response: tasked.free_response,
                    grader_points: nil,
                    grader_comments: nil,
                    needs_grading: false,
                    submitted_late: false
                  }
                else
                  {
                    task_step_id: ts.id,
                    is_completed: false,
                    points: task.past_due? ? 0.0 : nil,
                    needs_grading: false
                  }
                end
              end
            })
          end
          # expect(tasking_plan_output.students.map(&:deep_symbolize_keys)).to match(
          #   a_collection_including(*expected_headings)
          # )
          pp headings
          puts '-'*80
          pp expected_headings

          headings = tasking_plan_output.students.map(&:deep_symbolize_keys)
          expect(headings).to match(a_collection_including(*expected_headings))
        end
      end
    end

    context 'after task steps are marked as correct or incorrect' do
      it 'shows available points and total points/scores' do
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
          headings = tasking_plan_output.question_headings.map(&:symbolize_keys)
          expected_headings = tasks.first.task_steps.each_with_index.map do |task_step, index|
            title = "Q#{index + 1}"
            points_without_dropping = 1.0
            points = 1.0
            if task_step.fixed_group? && task_step.exercise?
              a_hash_including({
                title: title,
                points_without_dropping: points_without_dropping,
                points: points,
                type: 'MCQ',
                question_id: task_step.tasked.question_id,
                exercise_id: task_step.tasked.content_exercise_id
              })
            else
              a_hash_including({
                title: title,
                points_without_dropping: points_without_dropping,
                points: points,
                type: 'Tutor'
              })
            end
          end
          # TODO: figure out why this fails on CI but not locally
          # expect(headings).to match a_collection_including(*expected_headings)
          expect(tasking_plan_output.late_work_fraction_penalty).to eq late_work_penalty
          expect(tasking_plan_output.num_questions_dropped).to eq 0
          expect(tasking_plan_output.points_dropped).to eq 0.0
          fractions_array = tasks.map(&:score).compact
          expect(tasking_plan_output.total_fraction).to eq(
            fractions_array.sum(0.0)/fractions_array.size
          )
          expect(tasking_plan_output.gradable_step_count).to eq 0
          expect(tasking_plan_output.ungraded_step_count).to eq 0
          grades_need_publishing = task_plan.grading_template.auto_grading_feedback_on_publish?
          expect(tasking_plan_output.grades_need_publishing).to eq grades_need_publishing

          available_points = tasking_plan_output.question_headings.sum{ |h| h.points_without_dropping }
          expected_scores = tasks.each_with_index.map do |task, index|
            student = task.taskings.first.role.student
            is_worked = index < 4
            is_correct = [ 0, 2, 3 ].include?(index)

            a_hash_including({
              role_id: task.taskings.first.entity_role_id,
              task_id: task.id,
              available_points: available_points,
              first_name: student.first_name,
              last_name: student.last_name,
              late_work_point_penalty: is_correct ? task.late_work_point_penalty : 0.0,
              is_dropped: false,
              is_late: task.late?,
              student_identifier: student.student_identifier,
              total_fraction: task.score,
              total_points: task.points,
              questions: task.task_steps.map do |ts|
                if ts.exercise?
                  tasked = ts.tasked
                  points = if ts.completed?
                             is_correct ? 1.0 : task.completion_weight
                           else
                             task.past_due? ? 0.0 : nil
                           end

                  {
                    task_step_id: ts.id,
                    exercise_id: tasked.content_exercise_id,
                    question_id: tasked.question_id,
                    is_completed: ts.completed?,
                    is_correct: is_correct,
                    selected_answer_id: tasked.answer_id,
                    points: points,
                    late_work_point_penalty: 0.0,
                    free_response: tasked.free_response,
                    grader_points: nil,
                    grader_comments: nil,
                    needs_grading: false,
                    submitted_late: false
                  }
                else
                  {
                    task_step_id: ts.id,
                    is_completed: false,
                    points: task.past_due? ? 0.0 : nil,
                    needs_grading: false
                  }
                end
              end,
              grades_need_publishing: grades_need_publishing && is_worked
            })
          end
          expect(tasking_plan_output.students.map(&:deep_symbolize_keys)).to match(
            a_collection_including(*expected_scores)
          )
        end
      end
    end
  end

  context 'external' do
    let(:task_plan) { external_task_plan }

    context 'with an unworked plan' do
      it 'shows all steps as incomplete' do
        scores.each_with_index do |tasking_plan_output, index|
          tasking_plan = tasking_plans[index]
          period = tasking_plan.target

          expect(tasking_plan_output.id).to eq tasking_plan.id
          expect(tasking_plan_output.period_id).to eq period.id
          expect(tasking_plan_output.period_name).to eq period.name
          expect(tasking_plan_output.question_headings.map(&:symbolize_keys)).to eq(
            tasks.first.task_steps.each_with_index.map do |task_step, index|
              { title: 'Clicked' }
            end
          )
          expect(tasking_plan_output.late_work_fraction_penalty).to eq late_work_penalty
          expect(tasking_plan_output.num_questions_dropped).to eq 0
          expect(tasking_plan_output.points_dropped).to eq 0.0
          expect(tasking_plan_output.total_fraction).to be_nil
          expect(tasking_plan_output.gradable_step_count).to eq 0
          expect(tasking_plan_output.ungraded_step_count).to eq 0
          expect(tasking_plan_output.grades_need_publishing).to eq false

          expect(tasking_plan_output.students.map(&:deep_symbolize_keys)).to eq(
            tasks.map do |task|
              student = task.taskings.first.role.student

              {
                role_id: task.taskings.first.entity_role_id,
                task_id: task.id,
                available_points: 0.0,
                first_name: student.first_name,
                last_name: student.last_name,
                late_work_point_penalty: 0.0,
                is_dropped: false,
                is_late: task.late?,
                student_identifier: student.student_identifier,
                total_fraction: nil,
                total_points: nil,
                questions: task.task_steps.map do |ts|
                  {
                    task_step_id: ts.id,
                    is_completed: false,
                    needs_grading: false
                  }
                end,
                grades_need_publishing: false
              }
            end
          )
        end
      end
    end

    context 'after task steps are marked as completed' do
      it 'shows viewed steps as completed' do
        MarkTaskStepCompleted.call task_step: tasks.first.task_steps.first

        scores.each_with_index do |tasking_plan_output, index|
          tasking_plan = tasking_plans[index]
          period = tasking_plan.target

          expect(tasking_plan_output.id).to eq tasking_plan.id
          expect(tasking_plan_output.period_id).to eq period.id
          expect(tasking_plan_output.period_name).to eq period.name
          expect(tasking_plan_output.question_headings.map(&:symbolize_keys)).to eq(
            tasks.first.task_steps.each_with_index.map do |task_step, index|
              { title: 'Clicked' }
            end
          )
          expect(tasking_plan_output.late_work_fraction_penalty).to eq late_work_penalty
          expect(tasking_plan_output.num_questions_dropped).to eq 0
          expect(tasking_plan_output.points_dropped).to eq 0.0
          expect(tasking_plan_output.total_fraction).to be_nil
          expect(tasking_plan_output.gradable_step_count).to eq 0
          expect(tasking_plan_output.ungraded_step_count).to eq 0
          expect(tasking_plan_output.grades_need_publishing).to eq false

          expect(tasking_plan_output.students.map(&:deep_symbolize_keys)).to eq(
            tasks.map do |task|
              student = task.taskings.first.role.student

              {
                role_id: task.taskings.first.entity_role_id,
                task_id: task.id,
                available_points: 0.0,
                first_name: student.first_name,
                last_name: student.last_name,
                late_work_point_penalty: 0.0,
                is_dropped: false,
                is_late: task.late?,
                student_identifier: student.student_identifier,
                total_fraction: nil,
                total_points: nil,
                questions: task.task_steps.map do |ts|
                  {
                    task_step_id: ts.id,
                    is_completed: ts.completed?,
                    needs_grading: false
                  }
                end,
                grades_need_publishing: false
              }
            end
          )
        end
      end
    end
  end

  protected

  def work_task(task:, is_correct:, num_steps: nil)
    is_completed = num_steps.nil? ? true : ->(task_step, index) { index < num_steps }
    Preview::WorkTask[task: task, is_completed: is_completed, is_correct: is_correct]
  end
end
