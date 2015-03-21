class Domain::ResetPracticeWidget
  lev_routine express_output: :task

  uses_routine Domain::GetPracticeWidget
  uses_routine Tasks::Api::CreateTasking

  protected

  def exec(role:, page_ids:)

    # Get the existing practice widget and remove incomplete exercises from it
    # so they can be used in later practice

    existing_practice_task = run(Domain::GetPracticeWidget, role: role).outputs.task
    # TODO actually do the step removal
    
    # Create the new practice widget task.
    # For the first pass, create a new Task with 5 random exercise steps

    task = Task.new(task_type: 'practice',
                    title: 'Practice',
                    opens_at: Time.now)

    5.times do      
      step = TaskStep.new(task: task)

      exercise_content = OpenStax::Exercises::V1.fake_client.new_exercise_hash
      exercise = OpenStax::Exercises::V1::Exercise.new(exercise_content.to_json)

      step.tasked = TaskedExercise.new(task_step: step, 
                                       url: exercise.url,
                                       title: exercise.title, 
                                       content: exercise.content)

      task.task_steps << step
    end

    task.save!

    # Assign it to role inside the Task subsystem (might not have much in there now)

    run(Tasks::Api::CreateTasking, role: role, task: task)

    # return the Task

    outputs[:task] = task

  end
end