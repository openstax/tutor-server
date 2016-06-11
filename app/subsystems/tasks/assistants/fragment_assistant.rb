# An abstract assistant that builds tasks from fragments
class Tasks::Assistants::FragmentAssistant < Tasks::Assistants::GenericAssistant

  protected

  def task_fragments(task:, fragments:, page_title:, page:, related_content: nil)
    related_content ||= page.related_content
    title = page_title

    fragments.each do |fragment|

      title ||= fragment.title

      step_modifier = ->(step) {
        step.group_type = :core_group
        step.add_labels(fragment.labels)
        step.add_related_content(related_content)
      }

      step_builder = ->() {
        Tasks::Models::TaskStep.new(task: task).tap do |step|
          step_modifier.call(step)
          task.add_step(step)
        end
      }

      # For Exercise and OptionalExercise (subclass of Exercise)
      previous_step = task.task_steps.last if fragment.is_a? OpenStax::Cnx::V1::Fragment::Exercise

      case fragment
      # This is a subclass of Fragment::Exercise so it needs to come first
      when OpenStax::Cnx::V1::Fragment::OptionalExercise
        store_related_exercises(exercise_fragment: fragment, page: page,
                                previous_step: previous_step, title: title) \
          unless previous_step.nil?
      when OpenStax::Cnx::V1::Fragment::Exercise
        task_exercise(exercise_fragment: fragment, page: page, task: task, title: title,
                      previous_step: previous_step, step_modifier: step_modifier)
      when OpenStax::Cnx::V1::Fragment::Video
        task_video(video_fragment: fragment, step: step_builder.call, title: title)
      when OpenStax::Cnx::V1::Fragment::Interactive
        task_interactive(interactive_fragment: fragment, step: step_builder.call, title: title)
      else
        task_reading(reading_fragment: fragment, page: page, title: title, step: step_builder.call)
      end

      # The page title applies only to the first step in the set of fragments given
      title = nil

    end
  end

  def task_reading(reading_fragment:, page:, step:, title: nil)
    Tasks::Models::TaskedReading.new(task_step: step,
                                     url: page.url,
                                     book_location: page.book_location,
                                     title: title,
                                     content: reading_fragment.to_html)
  end

  def task_exercise(exercise_fragment:, page:, task:, title:, previous_step:, step_modifier:)
    exercise = get_random_unused_page_exercise_with_tags(page, exercise_fragment.embed_tags)

    if exercise.nil?
      node_id = exercise_fragment.node_id
      return if node_id.blank?

      feature_tag = "context-cnxfeature:#{node_id}"
      exercise = get_random_unused_page_exercise_with_tags(page, feature_tag)

      return if exercise.nil?
    end

    # Removes the current exercise's context from the previous step
    # Removes the previous step completely if this modification makes its content blank
    if previous_step.present? && exercise.context.present? &&
       previous_step.has_content? && previous_step.tasked.content.include?(exercise.context)
      previous_step.tasked.content = previous_step.tasked.content.sub(exercise.context, '')

      if previous_step.tasked.content.blank?
        task.task_steps.delete(previous_step)
      else
        previous_step.tasked.save! if previous_step.tasked.persisted?
      end
    end

    # Assign the exercise
    TaskExercise.call(exercise: exercise, title: title, task: task) do |step|
      step_modifier.call(step)
    end
  end

  def store_related_exercises(exercise_fragment:, page:, previous_step:, title: nil)
    pool_exercises = page.reading_context_pool.exercises
    tasked = previous_step.tasked

    related_exercises = \
    if tasked.is_a?(Tasks::Models::TaskedExercise) # Try Another
      # Retrieve an exercise related to the previous step by LO
      exercise = tasked.exercise

      los = Set.new exercise.los.map(&:id)
      aplos = Set.new exercise.aplos.map(&:id)

      pool_exercises.select do |ex|
        ex.los.any?{ |tag| los.include?(tag.id) } || ex.aplos.any?{ |tag| aplos.include?(tag.id) }
      end
    else # Try One (Exemplar)
      # Retrieve an exercise tagged with the context-cnxfeature tag
      node_id = exercise_fragment.node_id
      return if node_id.blank?

      feature_tag = "context-cnxfeature:#{node_id}"
      pool_exercises.select{ |ex| ex.tags.any?{ |tag| tag.value == feature_tag } }
    end

    previous_step.related_exercise_ids = related_exercises.map(&:id) || []
  end

  def task_video(video_fragment:, step:, title: nil)
    Tasks::Models::TaskedVideo.new(task_step: step,
                                   url: video_fragment.url,
                                   title: title,
                                   content: video_fragment.to_html)
  end

  def task_interactive(interactive_fragment:, step:, title: nil)
    Tasks::Models::TaskedInteractive.new(task_step: step,
                                         url: interactive_fragment.url,
                                         title: title,
                                         content: interactive_fragment.to_html)
  end

end
