require 'rails_helper'
require 'vcr_helper'

RSpec.describe Tasks::Assistants::HomeworkAssistant, :type => :assistant,
                                                     :vcr => VCR_OPTS do

  let!(:assistant) { FactoryGirl.create(
    :tasks_assistant, code_class_name: 'Tasks::Assistants::HomeworkAssistant'
  ) }

  let!(:exercises) {
    OpenStax::Exercises::V1.use_real_client
    Content::Routines::ImportExercises.call(tag: 'k12phys-ch04-s01-lo01')
                                      .outputs.exercises
  }

  let!(:exercise_ids) { exercises[1..-2].collect{|e| e.id} }
  let!(:tutor_exercise_count) { 4 } # Adjust if spaced practice changes

  let!(:task_plan) {
    FactoryGirl.create :tasks_task_plan, assistant: assistant, settings: {
      exercise_ids: exercise_ids, description: "Hello!"
    }
  }

  let!(:taskees) { 3.times.collect{ Entity::User.create } }
  let!(:tasking_plans) { taskees.collect { |t|
    task_plan.tasking_plans << FactoryGirl.create(
      :tasks_tasking_plan, task_plan: task_plan, target: t
    )
  } }

  it 'assigns the exercises chosen by the teacher and sets the description' do
    tasks = DistributeTasks.call(task_plan).outputs.tasks
    expect(tasks.length).to eq 3

    tasks.each do |task|
      expect(task.taskings.length).to eq 1
      expect(task.description).to eq "Hello!"
      task_steps = task.task_steps
      expect(task_steps.length).to(
        eq exercise_ids.length + tutor_exercise_count
      )

      task_steps[0..exercise_ids.length-1].each_with_index do |task_step, i|
        exercise = exercises[i+1]
        tasked = task_step.tasked
        expect(tasked).to be_a(Tasks::Models::TaskedExercise)
        expect(tasked.url).to eq(exercise.url)
        expect(tasked.title).to eq(exercise.title)
        expect(tasked.content).to eq(exercise.content)

        (task_steps - [task_step]).each do |other_step|
          expect(tasked.content).not_to(
            include(other_step.tasked.content)
          )
        end
      end
    end

    expected_roles = taskees.collect{ |t| Role::GetDefaultUserRole[t] }
    expect(tasks.collect{|t| t.taskings.first.role}).to eq expected_roles
  end

  # TODO (spaced practice etc)
  xit 'assigns the exercises chosen by tutor' do
  end

end
