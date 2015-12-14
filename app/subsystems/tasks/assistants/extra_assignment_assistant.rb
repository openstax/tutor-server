class Tasks::Assistants::ExtraAssignmentAssistant

  def self.schema
    '{
      "type": "object",
      "required": [
        "snap_lab_ids"
      ],
      "properties": {
        "snap_lab_ids": {
          "type": "array",
          "items": {
            "type": "string"
          }
        }
      },
      "additionalProperties": false
    }'
  end

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees
    collect_snap_labs
    @pages = result.pages
    @page_id_to_snap_lab_id = result.page_id_to_snap_lab_id

    @tag_exercise = {}
    @exercise_pages = {}
    @page_pools = {}
    @pool_exercises = {}
  end

  def build_tasks
    @taskees.collect do |taskee|
      build_extra_task(pages: @pages, page_id_to_snap_lab_id: @page_id_to_snap_lab_id).entity_task
    end
  end

  protected

  def collect_snap_labs
    raise 'No snap labs selected' if @task_plan.settings['snap_lab_ids'].blank?

    # Snap lab ids contains the page id and the snap lab note id
    # For example, on page id 100, a snap lab note with id "fs-id1164355841632"
    # the snap lab id is "100:fs-id1164355841632"
    page_to_snap_lab = Hash.new { |hash, key| hash[key] = [] }
    @task_plan.settings['snap_lab_ids'].each do |page_snap_lab_id|
      page_id, snap_lab_id = page_snap_lab_id.split(':', 2)
      page_to_snap_lab[page_id] << snap_lab_id
    end

    page_ids = page_to_snap_lab.keys
    @ecosystem = GetEcosystemFromIds.call(page_ids: page_ids)

    set(pages: @ecosystem.pages_by_ids(page_ids),
        page_id_to_snap_lab_id: page_to_snap_lab)
  end

  def build_extra_task(pages:, page_id_to_snap_lab_id:)
    task = build_task

    pages.each do |page|
      page.snap_labs.each do |snap_lab|
        # Snap lab ids contains the page id and the snap lab note id
        # For example, on page id 100, a snap lab note with id "fs-id1164355841632"
        # the snap lab id is "100:fs-id1164355841632"
        snap_lab_id = snap_lab[:id].split(':').last
        if page_id_to_snap_lab_id[page.id.to_s].include?(snap_lab_id)
          task_fragments(task: task, fragments: snap_lab[:fragments],
                         fragment_title: snap_lab[:title],
                         page: page)
        end
      end
    end

    task
  end

  def build_task
    title = @task_plan.title || 'Extra Assignment'
    description = @task_plan.description

    Tasks::BuildTask[
      task_plan: @task_plan,
      task_type: :extra,
      title: title,
      description: description,
      feedback_at: Time.now
    ]
  end

  def task_fragments(task:, fragments:, fragment_title:, page:)
    fragments.each do |fragment|
      step = Tasks::Models::TaskStep.new(task: task)

      case fragment
      when OpenStax::Cnx::V1::Fragment::Feature
        subfragments = fragment.fragments
        exercise_subfragments = subfragments.select(&:exercise?)
        if exercise_subfragments.count > 1
          # Remove all Exercise fragments and replace with an ExerciseChoice
          subfragments = subfragments - exercise_subfragments
          subfragments << OpenStax::Cnx::V1::Fragment::ExerciseChoice.new(
            node: nil, title: nil, exercise_fragments: exercise_subfragments
          )
        end

        task_fragments(task: task, fragments: subfragments, fragment_title: fragment_title,
                       page: page)
      when OpenStax::Cnx::V1::Fragment::ExerciseChoice
        tasked_exercise_choice(exercise_choice_fragment: fragment,
                               step: step, title: fragment_title)
      when OpenStax::Cnx::V1::Fragment::Exercise
        tasked_exercise(exercise_fragment: fragment, step: step, title: fragment_title)
      when OpenStax::Cnx::V1::Fragment::Video
        tasked_video(video_fragment: fragment, step: step, title: fragment_title)
      when OpenStax::Cnx::V1::Fragment::Interactive
        tasked_interactive(interactive_fragment: fragment, step: step, title: fragment_title)
      else
        tasked_reading(reading_fragment: fragment, page: page, title: fragment_title, step: step)
      end

      next if step.tasked.nil?
      task.task_steps << step
    end
  end

  def tasked_reading(reading_fragment:, page:, step:, title: nil)
    Tasks::Models::TaskedReading.new(task_step: step,
                                     url: page.url,
                                     book_location: page.book_location,
                                     title: title,
                                     content: reading_fragment.to_html)
  end

  def tasked_exercise_choice(exercise_choice_fragment:, step:, title: nil)
    exercises = exercise_choice_fragment.exercise_fragments
    if exercises.empty?
      logger.warn "Exercise Choice without Exercises found while creating iReading"
      return
    end

    chosen_exercise = exercises.sample
    case chosen_exercise
    when OpenStax::Cnx::V1::Fragment::Exercise
      tasked_exercise(exercise_fragment: chosen_exercise, step: step,
                      can_be_recovered: true, title: title)
    when OpenStax::Cnx::V1::Fragment::ExerciseChoice
      tasked_exercise_choice(exercise_choice_fragment: chosen_exercise, step: step, title: title)
    else
      logger.warn "Exercise Choice with invalid Exercise fragment found while creating iReading"
    end
  end

  def tasked_exercise(exercise_fragment:, step:, can_be_recovered: false, title: nil)
    if exercise_fragment.embed_tag.blank?
      logger.warn "Exercise without embed tag found while creating iReading"
      return
    end

    # Search Ecosystem Exercises for one matching the embed tag
    exercise = get_first_tag_exercise(exercise_fragment.embed_tag)
    unless exercise.nil?
      TaskExercise.call(exercise: exercise, title: title,
                        can_be_recovered: can_be_recovered, task_step: step)
    end
  end

  def tasked_video(video_fragment:, step:, title: nil)
    if video_fragment.url.blank?
      logger.warn "Video without embed tag found while creating iReading"
      return
    end

    Tasks::Models::TaskedVideo.new(task_step: step,
                                   url: video_fragment.url,
                                   title: title,
                                   content: video_fragment.to_html)
  end

  def tasked_interactive(interactive_fragment:, step:, title: nil)
    if interactive_fragment.url.blank?
      logger.warn('Interactive without url found while creating iReading')
      return
    end

    Tasks::Models::TaskedInteractive.new(task_step: step,
                                         url: interactive_fragment.url,
                                         title: title,
                                         content: interactive_fragment.to_html)
  end

  def get_first_tag_exercise(tag)
    @tag_exercise[tag] ||= @ecosystem.exercises_with_tags(tag).first
  end

  def get_exercise_pages(ex)
    @exercise_pages[ex.id] ||= ex.page
  end

  def get_page_pools(pages)
    page_ids = pages.collect{ |pg| pg.id }
    @page_pools[page_ids] ||= @ecosystem.reading_dynamic_pools(pages: pages)
  end

  def get_pool_exercises(pool)
    @pool_exercises[pool.uuid] ||= pool.exercises
  end

  def logger
    Rails.logger
  end

end
