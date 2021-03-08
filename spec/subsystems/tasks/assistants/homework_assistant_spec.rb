require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::HomeworkAssistant, type: :assistant, vcr: VCR_OPTS do
  before(:all) do
    @assistant = \
      FactoryBot.create(:tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant')
  end

  context "for Introduction and Force" do
    before(:all) do
      DatabaseCleaner.start

      generate_homework_test_exercise_content

      core_exercise_ids = @pages.flat_map(&:homework_core_exercise_ids)[1..5]

      @teacher_selected_exercises = Content::Models::Exercise.where(id: core_exercise_ids)

      @exercises_count_dynamic = 4

      @assignment_exercise_count = @teacher_selected_exercises.size + @exercises_count_dynamic

      @task_plan = FactoryBot.build(
        :tasks_task_plan,
        assistant: @assistant,
        content_ecosystem_id: @ecosystem.id,
        description: "Hello!",
        settings: {
          exercises: @teacher_selected_exercises.map do |exercise|
            { id: exercise.id.to_s, points: [ 1 ] * exercise.number_of_questions }
          end,
          exercises_count_dynamic: @exercises_count_dynamic
        },
        num_tasking_plans: 0
      )

      course = @task_plan.course

      period = FactoryBot.create :course_membership_period, course: course

      num_taskees = 3

      @taskee_users = num_taskees.times.map do
        FactoryBot.create(:user_profile).tap do |user|
          AddUserAsPeriodStudent.call(user: user, period: period)
        end
      end

      @taskee_users.each do |taskee|
        @task_plan.tasking_plans << FactoryBot.build(
          :tasks_tasking_plan,
          task_plan: @task_plan,
          target: taskee
        )
      end

      @task_plan.save!

      @tasks = DistributeTasks.call(task_plan: @task_plan).outputs.tasks
    end

    after(:all)  { DatabaseCleaner.clean }

    it "sets description, task type, and feedback enums" do
      grading_template = @task_plan.grading_template
      @tasks.each do |task|
        expect(task.description).to eq("Hello!")
        expect(task.homework?).to be_truthy
        # feedback enums copied from the task_plan's grading template
        expect(task.auto_grading_feedback_on).to eq grading_template.auto_grading_feedback_on
        expect(task.manual_grading_feedback_on).to eq grading_template.manual_grading_feedback_on
      end
    end

    it "creates one task per taskee" do
      expect(@tasks.count).to eq(@taskee_users.count)
    end

    it "assigns each task to one role" do
      @tasks.each { |task| expect(task.taskings.count).to eq(1) }

      expected_roles = @taskee_users.map{ |taskee| Role::GetDefaultUserRole[taskee] }
      expect(@tasks.map {|t| t.taskings.first.role}).to match_array expected_roles
    end

    it "assigns the correct number of exercises" do
      @tasks.each do |task|
        expect(9).to eq(@assignment_exercise_count)
      end
    end

    it "assigns the teacher-selected exercises as the task's core exercises" do
      @tasks.each do |task|
        core_task_steps = task.core_task_steps
        expect(5).to eq(@teacher_selected_exercises.size)

        exercise_index = 0
        question_index = 0
        core_task_steps.each do |task_step|
          tasked_exercise = task_step.tasked

          exercise = @teacher_selected_exercises[exercise_index]

          expect(tasked_exercise).to be_a(Tasks::Models::TaskedExercise)
          expect(tasked_exercise.url).to eq(exercise.url)
          expect(tasked_exercise.title).to eq(exercise.title)

          tasked_content = JSON.parse(tasked_exercise.content)
          exercise_content = JSON.parse(exercise.content)
          expect(tasked_content.except('questions')).to eq(exercise_content.except('questions'))
          expect(tasked_content['questions']).to(
            eq([ exercise_content['questions'][question_index] ])
          )

          if exercise_content['questions'].size > question_index + 1
            question_index += 1
          else
            exercise_index += 1
            question_index = 0
          end
        end
      end
    end

    it "assigns all available tutor slots as spaced practice exercise placeholders" do
      @tasks.each do |task|
        spaced_practice_task_steps = task.spaced_practice_task_steps
        expect(spaced_practice_task_steps.count).to eq @exercises_count_dynamic

        spaced_practice_task_steps.each do |task_step|
          expect(task_step.labels).to include 'review'
          tasked_placeholder = task_step.tasked
          expect(tasked_placeholder).to be_a(Tasks::Models::TaskedPlaceholder)
          expect(tasked_placeholder.exercise_type?).to be_truthy
        end

        expect(task.personalized_task_steps).to be_empty
      end
    end

    it "allows from 0 to 4 tutor slots" do
      (0..4).each { |tutor_slots| @task_plan.save! }

      @task_plan.settings['exercises_count_dynamic'] = 5

      expect(@task_plan.save).to eq false

      expect { @task_plan.save! }.to raise_error ActiveRecord::RecordInvalid
    end
  end
end
