# An abstract assistant that builds tasks from fragments
class Tasks::Assistants::FragmentAssistant < Tasks::Assistants::GenericAssistant

  protected

  def task_fragments(task:, fragments:, fragment_title:, page:, related_content: nil)
    title = fragment_title

    fragments.each do |fragment|
      step = Tasks::Models::TaskStep.new(task: task)

      case fragment
      when OpenStax::Cnx::V1::Fragment::Exercise
        task_exercise(exercise_fragment: fragment, page: page, step: step, title: title)
      when OpenStax::Cnx::V1::Fragment::OptionalExercise
        task_optional_exercise(exercise_fragment: fragment,
                               step: task.task_steps.last || step,
                               title: title)
      when OpenStax::Cnx::V1::Fragment::Video
        task_video(video_fragment: fragment, step: step, title: title)
      when OpenStax::Cnx::V1::Fragment::Interactive
        task_interactive(interactive_fragment: fragment, step: step, title: title)
      else
        task_reading(reading_fragment: fragment, page: page, title: title, step: step)
      end

      next if step.tasked.nil?
      step.group_type = :core_group
      step.add_labels(fragment.labels)
      related_content ||= page.related_content
      step.add_related_content(related_content)
      task.task_steps << step

      # The title applies only to the first step in the set of fragments given
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

  def task_exercise(exercise_fragment:, page:, step:, title: nil)
    exercise = get_random_unused_exercise_with_tags(exercise_fragment.embed_tags)

    if exercise.nil?
      node_id = exercise_fragment.node_id
      return if node_id.blank?

      feature_tag = "context-cnxfeature:#{page.uuid}:#{node_id}"
      exercise = get_random_unused_exercise_with_tags([feature_tag])

      return if exercise.nil?
    end

    # Assign the exercise
    TaskExercise[exercise: exercise, title: title, task_step: step]
  end

  def task_optional_exercise(exercise_fragment:, step:, title: nil)
    step.tasked.can_be_recovered = true
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
