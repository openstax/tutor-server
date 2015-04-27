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

  it 'assigns the exercises chosen by the teacher and sets the description and feedback_at' do
    tasks = DistributeTasks.call(task_plan).outputs.tasks
    expect(tasks.length).to eq num_taskees

    tasks.each do |task|
      expect(task.taskings.length).to eq 1
      expect(task.description).to eq "Hello!"
      expect(task.feedback_at).to eq task.due_at

      expect(task.task_steps.count).to eq(assignment_exercise_count)

      core_task_steps = task.core_task_steps
      expect(core_task_steps.count).to eq(teacher_selected_exercises.count)

      core_task_steps.each_with_index do |task_step, ii|
        tasked_exercise = task_step.tasked

        exercise = teacher_selected_exercises[ii]

        expect(tasked_exercise).to be_a(Tasks::Models::TaskedExercise)
        expect(tasked_exercise.url).to eq(exercise.url)
        expect(tasked_exercise.title).to eq(exercise.title)
        expect(tasked_exercise.content).to eq(exercise.content)

        other_task_steps = core_task_steps.reject{|ts| ts == task_step}
        other_task_steps.each do |other_step|
          expect(tasked_exercise.content).not_to(
            include(other_step.tasked.content)
          )
        end
      end

      spaced_practice_task_steps = task.spaced_practice_task_steps
      expect(spaced_practice_task_steps.count).to eq(tutor_selected_exercise_count)
    end

    expected_roles = taskees.collect{ |t| Role::GetDefaultUserRole[t] }
    expect(tasks.collect{|t| t.taskings.first.role}).to eq expected_roles
  end

  # TODO (spaced practice etc)
  xit 'assigns the exercises chosen by tutor' do
  end

end
