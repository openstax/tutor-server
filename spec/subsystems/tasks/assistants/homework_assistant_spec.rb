require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::HomeworkAssistant, :type => :assistant,
                                                     :vcr => VCR_OPTS do

  let!(:assistant) {
    FactoryGirl.create(:tasks_assistant,
      code_class_name: 'Tasks::Assistants::HomeworkAssistant'
    )
  }

  let!(:exercises) {
    OpenStax::Exercises::V1.use_real_client
    Content::Routines::ImportExercises.call(tag: 'k12phys-ch04-s01-lo01')
                                      .outputs.exercises
  }

  let!(:teacher_selected_exercises) { exercises[1..-2] }
  let!(:teacher_selected_exercise_ids) { teacher_selected_exercises.collect{|e| e.id} }

  let!(:tutor_selected_exercise_count) { 4 } # Adjust if spaced practice changes

  let!(:assignment_exercise_count) { teacher_selected_exercise_ids.count + tutor_selected_exercise_count }

  let!(:task_plan) {
    FactoryGirl.create(:tasks_task_plan,
      assistant: assistant,
      settings: {
        exercise_ids: teacher_selected_exercise_ids,
        exercises_count_dynamic: tutor_selected_exercise_count,
        description: "Hello!"
      }
    )
  }

  let!(:num_taskees) { 3 }

  let!(:taskees) { num_taskees.times.collect{ Entity::User.create } }

  let!(:tasking_plans) {
    taskees.collect do |taskee|
      task_plan.tasking_plans <<
        FactoryGirl.create(:tasks_tasking_plan,
          task_plan: task_plan,
          target:    taskee
        )
    end
  }

  it "sets description, task type, and feedback_at" do
    tasks = DistributeTasks.call(task_plan).outputs.tasks
    tasks.each do |task|
      expect(task.description).to eq("Hello!")
      expect(task.homework?).to be_truthy
      expect(task.feedback_at).to eq(task.due_at)
    end
  end

  it "creates one task per taskee" do
    tasks = DistributeTasks.call(task_plan).outputs.tasks
    expect(tasks.count).to eq(taskees.count)
  end

  it "assigns each task to one role" do
    tasks = DistributeTasks.call(task_plan).outputs.tasks
    tasks.each do |task|
      expect(task.taskings.count).to eq(1)
    end
    expected_roles = taskees.collect{ |taskee| Role::GetDefaultUserRole[taskee] }
    expect(tasks.collect{|t| t.taskings.first.role}).to eq expected_roles
  end

  it "assigns the correct number of exercises" do
    tasks = DistributeTasks.call(task_plan).outputs.tasks
    tasks.each do |task|
      expect(task.task_steps.count).to eq(assignment_exercise_count)
    end
  end

  it "assigns the teacher-selected exercises as the task's core exercises" do
    tasks = DistributeTasks.call(task_plan).outputs.tasks
    tasks.each do |task|
      core_task_steps = task.core_task_steps
      expect(core_task_steps.count).to eq(teacher_selected_exercises.count)

      core_task_steps.each_with_index do |task_step, ii|
        tasked_exercise = task_step.tasked

        exercise = teacher_selected_exercises[ii]

        expect(tasked_exercise).to be_a(Tasks::Models::TaskedExercise)
        expect(tasked_exercise.url).to eq(exercise.url)
        expect(tasked_exercise.title).to eq(exercise.title)
        expect(tasked_exercise.content).to eq(exercise.content)
      end
    end
  end

  it "assigns the tutor-selected spaced practice exercises" do
    tasks = DistributeTasks.call(task_plan).outputs.tasks
    tasks.each do |task|
      spaced_practice_task_steps = task.spaced_practice_task_steps
      expect(spaced_practice_task_steps.count).to eq(tutor_selected_exercise_count)
    end
  end

end
