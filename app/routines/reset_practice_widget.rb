class Domain::ResetPracticeWidget
  lev_routine express_output: :task

  uses_routine Domain::GetPracticeWidget
  uses_routine Tasks::CreateTasking

  protected

  def exec(role:, condition:, page_ids: [], book_part_ids: [])

    # Get the existing practice widget and remove incomplete exercises from it
    # so they can be used in later practice

    existing_practice_task = run(Domain::GetPracticeWidget, role: role).outputs
                                                                       .task
    # TODO actually do the step removal

    # Gather relevant LO's from pages and book_parts

    los = Content::GetLos[page_ids: page_ids, book_part_ids: book_part_ids]

    # Gather 5 exercises

    exercises = case condition
    when :fake
      get_fake_exercises(count: 5)
    when :local
      get_local_exercises(count: 5, role: role, tags: los)
    else
      get_biglearn_exercises(count: 5, role: role, tags: los)
    end

    # Create the new practice widget task, and put the exercises into steps

    # TODO move this whole routine into Tasks, use run(...) here

    task = Tasks::CreateTask[task_type: 'practice',
                             title: 'Practice',
                             opens_at: Time.now]

    exercises.each do |exercise|
      step = Tasks::Models::TaskStep.new(task: task)

      step.tasked = Domain::TaskExercise[exercise: exercise, task_step: step]

      task.task_steps << step
    end

    task.save!

    # Assign it to role inside the Task subsystem (might not have much in there now)

    run(Tasks::CreateTasking, role: role, task: task.entity_task)

    # return the Task

    outputs[:task] = task.entity_task
  end

  def get_fake_exercises(count:)
    count.times.collect do
      exercise_content = OpenStax::Exercises::V1.fake_client.new_exercise_hash
      exercise = OpenStax::Exercises::V1::Exercise.new(exercise_content.to_json)
    end
  end

  def get_local_exercises(count:, role:, tags:)
    exercises = Domain::SearchLocalExercises[not_assigned_to: role,
                                             tags: tags].to_a.shuffle

    count.times.collect do
      exercise = exercises.pop

      if exercise.nil?
        # We ran out of exercises, so start repeating them
        exercises = Domain::SearchLocalExercises[tags: tags].to_a.shuffle
        exercise = exercises.pop

        fatal_error(code: :no_exercises_found,
                    message: "No exercises matched the given ID's") \
          if exercise.nil?
      end

      exercise
    end
  end

  def get_biglearn_exercises(count:, role:, tags:)
    condition = condition_tags(tags)

    exercise_uids = OpenStax::BigLearn::V1.get_projection_exercises(
      user: role , tag_search: condition, count: 5,
      difficulty: 0.5, allow_repetitions: true
    )

    urls = exercise_uids.collect{|uid| "http://exercises.openstax.org/exercises/#{uid}"}

    Content::Exercise.where{url.in urls}.all.collect do |content_exercise|
      OpenStax::Exercises::V1::Exercise.new(content_exercise.content)
    end
  end

  def condition_tags(condition)
    condition
  end

end
