class ResetPracticeWidget
  lev_routine express_output: :task

  uses_routine GetPracticeWidget, as: :get_practice_widget

  uses_routine Tasks::CreateTasking,
    translations: { outputs: { type: :verbatim } },
    as: :create_tasking

  uses_routine Tasks::CreatePracticeWidgetTask,
    translations: { outputs: { type: :verbatim } },
    as: :create_practice_widget_task

  protected

  BASE_RELATION = Content::Models::Exercise.preload(exercise_tags: {tag: {page_tags: :page}})

  def exec(role:, exercise_source:, page_ids: [], book_part_ids: [], randomize: true)
    page_ids = [page_ids].flatten
    book_part_ids = [book_part_ids].flatten

    # Get the existing practice widget and remove incomplete exercises from it
    # so they can be used in later practice
    existing_practice_task = run(:get_practice_widget, role: role).outputs.task.try(:task)
    existing_practice_task.task_steps.incomplete.destroy_all unless existing_practice_task.nil?

    # Gather relevant LO's from pages and book_parts
    los = Content::GetLos[page_ids: page_ids, book_part_ids: book_part_ids]

    # Gather 5 exercises
    count = 5
    exercises = case exercise_source
                when :fake
                  get_fake_exercises(count)
                when :local
                  get_local_exercises(count, role, los, randomize: randomize)
                when :biglearn
                  get_biglearn_exercises(count, role, los)
                else
                  raise ArgumentError,
                        "exercise_source: must be one of [:fake, :local, :biglearn]"
                end

    num_exercises = exercises.size

    if num_exercises < count
      # Not enough exercises
      fatal_error(
        code: :not_enough_exercises,
        message: "Not enough exercises to build the Practice Widget. LO's: #{los.inspect}. Needed: #{count}. Got: #{num_exercises}"
      )
    end

    # Figure out the type of practice
    task_type = :mixed_practice
    task_type = :chapter_practice if book_part_ids.count > 0 && page_ids.count == 0
    task_type = :page_practice if book_part_ids.count == 0 && page_ids.count > 0

    related_content_array = exercise_source == :fake ? [] : \
                            exercises.collect{ |ex| get_related_content_for(ex) }

    # Create the new practice widget task, and put the exercises into steps
    run(:create_practice_widget_task, exercises: exercises,
                                      task_type: task_type,
                                      related_content_array: related_content_array)

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
    exercise_pool = SearchLocalExercises[relation: BASE_RELATION,
                                         not_assigned_to: role,
                                         tag: tags,
                                         match_count: 1]
    exercise_pool = exercise_pool.shuffle if options[:randomize]
    exercises = exercise_pool.first(count)
    num_exercises = exercises.size

    if num_exercises < count
      # We ran out of exercises, so start repeating them
      exercise_pool = SearchLocalExercises[relation: BASE_RELATION,
                                           assigned_to: role,
                                           tag: tags,
                                           match_count: 1]
      exercise_pool = exercise_pool.shuffle if options[:randomize]
      exercises = exercises + exercise_pool.first(count - num_exercises)
    end

    exercises
  end

  def get_biglearn_exercises(count, role, los)
    urls = OpenStax::Biglearn::V1.get_projection_exercises(
      role: role , tag_search: { _or: los }, count: 5, difficulty: 0.5, allow_repetitions: true
    )

    exercises = SearchLocalExercises[relation: BASE_RELATION, url: urls]
  end

  def get_related_content_for(exercise)
    page = exercise_page(exercise)

    { title: page.title, chapter_section: page.chapter_section }
  end

  def exercise_page(exercise)
    tags = exercise._repository.exercise_tags.collect{ |et| et.tag }
    los = tags.select{ |tag| tag.lo? || tag.aplo? }
    pages = los.collect{ |lo| lo.page_tags.collect{ |pt| pt.page } }.flatten.compact

    if pages.one?
      pages.first
    else
      raise "#{pages.count} pages found for exercise #{exercise.url}"
    end
  end

end
