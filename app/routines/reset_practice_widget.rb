class ResetPracticeWidget
  lev_routine express_output: :task

  uses_routine GetPracticeWidget,
    translations: { outputs: { type: :verbatim } },
    as: :get_practice_widget

  uses_routine Tasks::CreateTasking,
    translations: { outputs: { type: :verbatim } },
    as: :create_tasking

  uses_routine Tasks::CreatePracticeWidgetTask,
    translations: { outputs: { type: :verbatim } },
    as: :create_practice_widget_task

  protected
  def exec(role:, exercise_source:, page_ids: [], book_part_ids: [], randomize: true)
    page_ids = [page_ids].flatten
    book_part_ids = [book_part_ids].flatten

    # Get the existing practice widget and remove incomplete exercises from it
    # so they can be used in later practice
    # run(:get_practice_widget, role: role)
    # TODO actually do the step removal

    # Gather relevant LO's from pages and book_parts
    los = Content::GetLos[page_ids: page_ids, book_part_ids: book_part_ids]

    # Gather 5 exercises
    exercises = case exercise_source
                when :fake
                  get_fake_exercises(5)
                when :local
                  get_local_exercises(5, role, los, { randomize: randomize })
                when :biglearn
                  get_biglearn_exercises(5, role, los)
                else
                  raise ArgumentError,
                        "exercise_source: must be one of [:fake, :local, :biglearn]"
                end

    # Create the new practice widget task, and put the exercises into steps
    task_type = if book_part_ids.count == 1
                  :chapter_practice
                elsif page_ids.count == 1
                  :page_practice
                end

    run(:create_practice_widget_task, add_related_content: exercise_source != :fake,
                                      exercises: exercises,
                                      task_type: task_type)

    run(:create_tasking, role: role, task: outputs.task.entity_task)

    outputs.task = outputs.task.entity_task
  end

  def get_fake_exercises(count)
    count.times.collect do
      exercise_content = OpenStax::Exercises::V1.fake_client.new_exercise_hash
      exercise = OpenStax::Exercises::V1::Exercise.new content: exercise_content.to_json
    end
  end

  def get_local_exercises(count, role, tags, options = {})
    options = { randomize: true }.merge(options)
    exercises = SearchLocalExercises[not_assigned_to: role,
                                     tag: tags,
                                     match_count: 1].to_a
    exercises = exercises.shuffle if options[:randomize]

    count.times.collect do
      unless exercise = exercises.pop
        # We ran out of exercises, so start repeating them
        exercises = SearchLocalExercises[assigned_to: role,
                                         tag: tags,
                                         match_count: 1].to_a
        exercises = exercises.shuffle if options[:randomize]

        unless exercise = exercises.pop
          fatal_error(code: :no_exercises_found,
                      message: "No exercises matched the given tags: #{tags.inspect}")
        end
      end

      exercise
    end
  end

  def get_biglearn_exercises(count, role, los)
    condition = biglearn_condition(los)

    urls = OpenStax::Biglearn::V1.get_projection_exercises(
      role: role , tag_search: condition, count: 5,
      difficulty: 0.5, allow_repetitions: true
    )

    Content::Models::Exercise.where{url.in urls}.all.collect do |content_exercise|
      OpenStax::Exercises::V1::Exercise.new(content: content_exercise.content)
    end
  end

  def biglearn_condition(los)
    {
      _or: los
    }
  end
end
