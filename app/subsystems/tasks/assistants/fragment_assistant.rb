# An abstract assistant that builds tasks from fragments
class Tasks::Assistants::FragmentAssistant < Tasks::Assistants::GenericAssistant

  protected

  def task_fragments(task:, fragments:, page_title:, page:, related_content: nil)
    related_content ||= page.related_content
    title = page_title

    step_builder = ->(fragment) do
      Tasks::Models::TaskStep.new(task: task).tap do |step|
        step.group_type = :core_group
        step.add_labels(fragment.labels)
        step.add_related_content(related_content)
        task.add_step(step)
      end
    end

    fragments.each do |fragment|

      title ||= fragment.title

      # For Exercise and OptionalExercise (subclass of Exercise)
      previous_step = task.task_steps.last if fragment.is_a? OpenStax::Cnx::V1::Fragment::Exercise

      case fragment
      # This is a subclass of Fragment::Exercise so it needs to come first
      when OpenStax::Cnx::V1::Fragment::OptionalExercise
        store_related_exercises(exercise_fragment: fragment, page: page,
                                previous_step: previous_step, title: title) \
          unless previous_step.nil?
      when OpenStax::Cnx::V1::Fragment::Exercise
        task_exercise(exercise_fragment: fragment, page: page, task: task,
                      previous_step: previous_step, title: title)
      when OpenStax::Cnx::V1::Fragment::Video
        task_video(video_fragment: fragment, step: step_builder.call(fragment), title: title)
      when OpenStax::Cnx::V1::Fragment::Interactive
        task_interactive(interactive_fragment: fragment,
                         step: step_builder.call(fragment), title: title)
      else
        task_reading(reading_fragment: fragment, page: page,
                     step: step_builder.call(fragment), title: title)
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

  def task_exercise(exercise_fragment:, page:, task:, title:, previous_step:)
    exercise = get_random_unused_page_exercises_with_tags(
      page: page, tags: exercise_fragment.embed_tags, count: 1
    ).first

    if exercise.nil?
      node_id = exercise_fragment.node_id
      return if node_id.blank?

      feature_tag = "context-cnxfeature:#{node_id}"
      exercise = get_random_unused_page_exercise_with_tags(
        page: page, tags: feature_tag, count: 1
      ).first

      return if exercise.nil?
    end

    # Removes the current exercise's context from the previous step
    # Removes the previous step completely if this modification makes its content blank
    if previous_step.present? && previous_step.has_content? && exercise.context.present?
      node = Nokogiri::HTML.fragment(previous_step.tasked.content)

      # Remove any feature_ids used as exercise context from the previous step
      feature_node = OpenStax::Cnx::V1::Page.feature_node(node, exercise.feature_ids)

      unless feature_node.nil?
        # Remove context from previous step
        feature_node.remove
        previous_step.tasked.content = node.to_html

        if previous_step.tasked.content.blank?
          # If the previous step is now blank, remove it from the task
          task.task_steps.delete(previous_step)
        else
          # If the previous step is persisted, save it again
          previous_step.tasked.save! if previous_step.tasked.persisted?
        end
      end
    end

    # Assign the exercise
    add_exercise_step!(task: task, exercise: exercise, title: title,
                       group_type: :core_group, labels: exercise_fragment.labels)
  end

  def store_related_exercises(exercise_fragment:, page:, previous_step:, title: nil)
    @related_exercise_ids ||= {}

    unless @related_exercise_ids.has_key?(exercise_fragment)
      pool_exercises = page.reading_context_pool.exercises(preload: :tags)
      tasked = previous_step.tasked

      related_exercises = \
      if tasked.is_a?(Tasks::Models::TaskedExercise) # Try Another
        # Retrieve an exercise related to the previous step by LO
        exercise = tasked.exercise

        lo_ids = exercise.los.map(&:id)
        aplo_ids = exercise.aplos.map(&:id)

        pool_exercises.select do |ex|
          ex.los.any?{ |lo| lo_ids.include?(lo.id) } ||
          ex.aplos.any?{ |aplo| aplo_ids.include?(aplo.id) }
        end
      else # Try One (Exemplar)
        # Retrieve an exercise tagged with the context-cnxfeature tag
        node_id = exercise_fragment.node_id
        return if node_id.blank?

        feature_tag_value = "context-cnxfeature:#{node_id}"
        pool_exercises.select{ |ex| ex.tags.any?{ |tag| tag.value == feature_tag_value } }
      end

      @related_exercise_ids[exercise_fragment] = related_exercises.map(&:id) || []
    end

    previous_step.related_exercise_ids = @related_exercise_ids[exercise_fragment]
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
