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

      core_pools = @ecosystem.homework_core_pools(pages: @pages)
      core_exercises = core_pools.flat_map(&:exercises).sort_by(&:uid)

      dynamic_pools = @ecosystem.homework_dynamic_pools(pages: @pages)
      dynamic_exercises = dynamic_pools.flat_map(&:exercises).sort_by(&:uid)

      @teacher_selected_exercises = core_exercises[1..5]
      teacher_selected_exercise_ids = @teacher_selected_exercises.map{|e| e.id.to_s}

      @tutor_selected_exercise_count = 4

      @assignment_exercise_count = teacher_selected_exercise_ids.count +
                                   @tutor_selected_exercise_count

      task_plan = FactoryBot.build(:tasks_task_plan,
        assistant: @assistant,
        content_ecosystem_id: @ecosystem.id,
        description: "Hello!",
        is_feedback_immediate: true,
        settings: {
          exercise_ids: teacher_selected_exercise_ids,
          exercises_count_dynamic: @tutor_selected_exercise_count
        },
        num_tasking_plans: 0
      )

      course = task_plan.owner.tap do |course|
        AddEcosystemToCourse[course: course, ecosystem: @ecosystem]
      end

      period = FactoryBot.create :course_membership_period, course: course

      num_taskees = 3

      @taskee_users = num_taskees.times.map do
        FactoryBot.create(:user).tap do |user|
          AddUserAsPeriodStudent.call(user: user, period: period)
        end
      end

      @taskee_users.each do |taskee|
        task_plan.tasking_plans << FactoryBot.create(
          :tasks_tasking_plan,
          task_plan: task_plan,
          target:    taskee.to_model
        )
      end

      task_plan.save!

      @tasks = DistributeTasks.call(task_plan: task_plan).outputs.tasks
    end

    after(:all)  { DatabaseCleaner.clean }

    it "sets description, task type, and feedback_at" do
      @tasks.each do |task|
        expect(task.description).to eq("Hello!")
        expect(task.homework?).to be_truthy
        # feedback_at == nil because the task plan was set to immediate_feedback
        expect(task.feedback_at).to be_nil
      end
    end

    it "creates one task per taskee" do
      expect(@tasks.count).to eq(@taskee_users.count)
    end

    it "assigns each task to one role" do
      @tasks.each { |task| expect(task.taskings.count).to eq(1) }

      expected_roles = @taskee_users.map{ |taskee| Role::GetDefaultUserRole[taskee] }
      expect(@tasks.map{|t| t.taskings.first.role}).to match_array expected_roles
    end

    it "assigns the correct number of exercises" do
      @tasks.each do |task|
        expect(task.task_steps.count).to eq(@assignment_exercise_count)
      end
    end

    it "assigns the teacher-selected exercises as the task's core exercises" do
      @tasks.each do |task|
        core_task_steps = task.core_task_steps
        expect(core_task_steps.count).to eq(@teacher_selected_exercises.count)

        core_task_steps.each_with_index do |task_step, ii|
          tasked_exercise = task_step.tasked

          exercise = @teacher_selected_exercises[ii]

          expect(tasked_exercise).to be_a(Tasks::Models::TaskedExercise)
          expect(tasked_exercise.url).to eq(exercise.url)
          expect(tasked_exercise.title).to eq(exercise.title)
          expect(tasked_exercise.content).to eq(exercise.content)
        end
      end
    end

    it "assigns all available tutor slots as spaced practice exercise placeholders" do
      @tasks.each do |task|
        spaced_practice_task_steps = task.spaced_practice_task_steps
        expect(spaced_practice_task_steps.count).to eq @tutor_selected_exercise_count

        spaced_practice_task_steps.each do |task_step|
          expect(task_step.labels).to include 'review'
          tasked_placeholder = task_step.tasked
          expect(tasked_placeholder).to be_a(Tasks::Models::TaskedPlaceholder)
          expect(tasked_placeholder.exercise_type?).to be_truthy
        end

        expect(task.personalized_task_steps).to be_empty
      end
    end
  end

end
