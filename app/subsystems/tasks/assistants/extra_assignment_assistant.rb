class Tasks::Assistants::ExtraAssignmentAssistant < Tasks::Assistants::GenericAssistant

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
    super

    outputs = collect_snap_labs
    @pages = outputs[:pages]
    @page_id_to_snap_lab_id = outputs[:page_id_to_snap_lab_id]

    @tag_exercises = {}
    @exercise_pages = {}
    @page_pools = {}
    @pool_exercises = {}
  end

  def build_tasks
    @taskees.map do |taskee|
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
    @ecosystem = GetEcosystemFromIds[page_ids: page_ids]

    {
      pages: @ecosystem.pages_by_ids(page_ids),
      page_id_to_snap_lab_id: page_to_snap_lab
    }
  end

  def build_extra_task(pages:, page_id_to_snap_lab_id:)
    task = build_task
    @used_embed_tags = []

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
      when OpenStax::Cnx::V1::Fragment::Exercise
        tasked_exercise(exercise_fragment: fragment, step: step, title: fragment_title)
      when OpenStax::Cnx::V1::Fragment::OptionalExercise
        tasked_optional_exercise(exercise_fragment: fragment,
                                 step: task.task_steps.last || step,
                                 title: fragment_title)
      when OpenStax::Cnx::V1::Fragment::Video
        tasked_video(video_fragment: fragment, step: step, title: fragment_title)
      when OpenStax::Cnx::V1::Fragment::Interactive
        tasked_interactive(interactive_fragment: fragment, step: step, title: fragment_title)
      else
        tasked_reading(reading_fragment: fragment, page: page, title: fragment_title, step: step)
      end

      task.task_steps << step unless step.tasked.nil?
    end
  end

  def tasked_reading(reading_fragment:, page:, step:, title: nil)
    Tasks::Models::TaskedReading.new(task_step: step,
                                     url: page.url,
                                     book_location: page.book_location,
                                     title: title,
                                     content: reading_fragment.to_html)
  end

  def tasked_exercise(exercise_fragment:, step:, title: nil)
    candidate_embed_tags = exercise_fragment.embed_tags - @used_embed_tags

    return if candidate_embed_tags.empty?

    # Search Ecosystem Exercises for one matching one of the embed tags
    chosen_embed_tag = candidate_embed_tags.sample
    exercise = get_random_exercise_with_tag(chosen_embed_tag)

    unless exercise.nil?
      # Assign the exercise
      TaskExercise[exercise: exercise, title: title, task_step: step]
      @used_embed_tags << chosen_embed_tag
    end
  end

  def tasked_optional_exercise(exercise_fragment:, step:, title: nil)
    step.tasked.can_be_recovered = true
  end

  def tasked_video(video_fragment:, step:, title: nil)
    Tasks::Models::TaskedVideo.new(task_step: step,
                                   url: video_fragment.url,
                                   title: title,
                                   content: video_fragment.to_html)
  end

  def tasked_interactive(interactive_fragment:, step:, title: nil)
    Tasks::Models::TaskedInteractive.new(task_step: step,
                                         url: interactive_fragment.url,
                                         title: title,
                                         content: interactive_fragment.to_html)
  end

  def get_random_exercise_with_tag(tag)
    @tag_exercises[tag] ||= @ecosystem.exercises_with_tags(tag)
    @tag_exercises[tag].sample
  end

  def get_exercise_pages(ex)
    @exercise_pages[ex.id] ||= ex.page
  end

  def get_page_pools(pages)
    page_ids = pages.map(&:id)
    @page_pools[page_ids] ||= @ecosystem.reading_dynamic_pools(pages: pages)
  end

  def get_pool_exercises(pool)
    @pool_exercises[pool.uuid] ||= pool.exercises
  end

  def logger
    Rails.logger
  end

end
