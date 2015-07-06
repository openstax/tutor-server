class ResetPracticeWidget
  lev_routine express_output: :task

  uses_routine GetPracticeWidget
  uses_routine Tasks::CreateTasking

  protected

  def exec(role:, exercise_source:, page_ids: [], book_part_ids: [], randomize: true)
    page_ids = [page_ids].flatten
    book_part_ids = [book_part_ids].flatten

    # Get the existing practice widget and remove incomplete exercises from it
    # so they can be used in later practice

    existing_practice_task = run(GetPracticeWidget, role: role).outputs.task
    # TODO actually do the step removal

    # Gather relevant LO's from pages and book_parts

    los = Content::GetLos[page_ids: page_ids, book_part_ids: book_part_ids]

    # Gather 5 exercises

    exercises = case exercise_source
    when :fake
      get_fake_exercises(count: 5)
    when :local
      get_local_exercises(count: 5, role: role, tags: los, randomize: randomize)
    when :biglearn
      get_biglearn_exercises(count: 5, role: role, los: los)
    else
      raise ArgumentError, "exercise_source: must be one of [:fake, :local, :biglearn]"
    end

    # Create the new practice widget task, and put the exercises into steps

    # TODO move this whole routine into Tasks, use run(...) here

    task_type = if book_part_ids.count == 1
                  :chapter_practice
                elsif page_ids.count == 1
                  :page_practice
                else
                  :mixed_practice
                end

    task = Tasks::BuildTask[task_type: task_type,
                            title: 'Practice',
                            opens_at: Time.now,
                            feedback_at: Time.now]

    exercises.each do |exercise|
      step = Tasks::Models::TaskStep.new(task: task)

      step.tasked = TaskExercise[exercise: exercise, task_step: step]

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
      exercise = OpenStax::Exercises::V1::Exercise.new(content: exercise_content.to_json)
    end
  end

  def get_local_exercises(count:, role:, tags:, randomize: true)
    exercises = SearchLocalExercises[not_assigned_to: role,
                                     tag: tags,
                                     match_count: 1,
                                     random: randomize]

    count.times.collect do
      unless exercise = exercises.pop
        # We ran out of exercises, so start repeating them
        exercises = SearchLocalExercises[assigned_to: role,
                                         tag: tags,
                                         match_count: 1,
                                         random: randomize]
        unless exercise = exercises.pop
          fatal_error(code: :no_exercises_found,
                      message: "No exercises matched the given tags: #{tags.inspect}")
        end
      end

      exercise
    end
  end

  def get_biglearn_exercises(count:, role:, los:)
    condition = biglearn_condition(los)

    urls = OpenStax::Biglearn::V1.get_projection_exercises(
      role: role , tag_search: condition, count: 5,
      difficulty: 0.5, allow_repetitions: true
    )

    exercises = Content::Models::Exercise.where{url.in urls}.all.collect do |content_exercise|
      OpenStax::Exercises::V1::Exercise.new(content: content_exercise.content)
    end
    exercises
  end

  def biglearn_condition(los)
    condition = {
      _or: los
    }

    condition
  end

end
