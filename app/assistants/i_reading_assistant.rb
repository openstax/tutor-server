class IReadingAssistant

  # Array of arrays [Events ago, number of spaced practice questions]
  # This has to change, but for now add 4 questions to simulate what
  # Kathi's algorithm would give us for a reading with 2 LO's
  # (the sample content)
  SPACED_PRACTICE_MAP = [[1, 4]]

  # Start creating readings here
  READING_ROOT_CSS = 'html > body'

  # Remove completely
  DISCARD_CSS = '.ost-reading-discard, .os-teacher'

  # Split iReading TaskSteps on these
  SPLIT_CSS = '.ost-assessed-feature, .ost-feature, .os-exercise, .ost-interactive, .ost-video'

  # Used to get TaskStep titles
  TITLE_CSS = "h1[data-type='title'], div[data-type='title']"

  # Just a page break
  ASSESSED_FEATURE_CSS = '.ost-assessed-feature'

  # Just a page break
  FEATURE_CSS = '.ost-feature'

  # Replace with actual Exercises and create TaskedExercises
  EXERCISE_CSS = '.os-exercise'

  # Replace with actual Interactives and create TaskedInteractives
  INTERACTIVE_CSS = '.ost-interactive'

  # Replace with actual Videos and create TaskedVideos
  VIDEO_CSS = '.ost-video'

  # Find the tag to search exercises by from this element
  EXERCISE_TAG_CSS = 'a[href~=\#ost\/api\/ex\/]'

  # Extract the tag from the above href using this regex
  EXERCISE_TAG_REGEX = /\A#ost\/api\/ex\/([\w-]+)\z/

  def self.schema
    '{
      "type": "object",
      "required": [
        "page_ids"
      ],
      "properties": {
        "page_ids": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        }
      },
      "additionalProperties": false
    }'
  end

  # Recursively removes a node and its empty parents
  def self.recursive_compact(node, stop_node)
    return if node == stop_node

    # Get parent
    parent = node.parent

    # Remove current node
    node.remove

    # Remove parent if empty
    recursive_compact(parent, stop_node) if parent.content.blank?
  end

  # Recursively removes all siblings before a node and its parents
  # Returns the stop_node
  def self.remove_before(node, stop_node)
    # Stopping condition
    return if node == stop_node

    # Get parent
    parent = node.parent

    # Get siblings
    siblings = parent.children

    # Get node's index
    index = siblings.index(node)

    # Remove siblings before node
    parent.children = siblings.slice(index..-1)

    # Remove nodes after the parent
    remove_before(parent, stop_node)
  end

  # Recursively removes all siblings after a node and its parents
  # Returns the stop_node
  def self.remove_after(node, stop_node)
    # Stopping condition
    return if node == stop_node

    # Get parent
    parent = node.parent

    # Get siblings
    siblings = parent.children

    # Get node's index
    index = siblings.index(node)

    # Remove siblings after node
    parent.children = siblings.slice(0..index)

    # Remove nodes after the parent
    remove_after(parent, stop_node)
  end

  def self.reading_attributes(node, url)
    {
      tasked_class: TaskedReading,
      title: node.at_css(TITLE_CSS).try(:content) || 'Reading',
      url: url,
      content: node.to_html
    }
  end

  def self.exercise_attributes(node)
    tag_link = node.at_css(EXERCISE_TAG_CSS).try(:value)
    tag = EXERCISE_TAG_REGEX.match(tag_link).try(:[], 1)
    ex = OpenStax::Exercises::V1.exercises(tag: tag)['items'].first

    ex.nil? ? nil : {
      tasked_class: TaskedExercise,
      title: ex.title || node.at_css(TITLE_CSS).try(:content),
      url: ex.url,
      content: ex.content
    }
  end

  def self.split_task_plan_content(task_plan)
    split_pages = []

    task_plan.settings['page_ids'].each do |page_id|
      page = Content::Api::GetPage.call(page_id: page_id).outputs.page
      doc = Nokogiri::HTML(page.content || '')

      # Find the root
      root = doc.at_css(READING_ROOT_CSS)
      return [] if root.nil?

      # Remove nodes with the discard tag
      root.css(DISCARD_CSS).remove

      # Initialize current_reading
      current_reading = root

      # Find first split
      split = current_reading.at_css(SPLIT_CSS)

      # Split the root and collect the TaskStep attributes
      while !split.nil? do
        split_attributes = []
        # Figure out what we just split on, testing in priority order
        if split.matches?(ASSESSED_FEATURE_CSS)
          # Assessed Feature
          exercise = split.at_css(EXERCISE_CSS)
          recursive_compact(exercise, split)

          split_attributes << reading_attributes(split, page.url)
          split_attributes << exercise_attributes(exercise)
        elsif split.matches?(FEATURE_CSS)
          # Feature
          split_attributes << reading_attributes(split, page.url)
        elsif split.matches?(EXERCISE_CSS)
          # Exercise
          split_attributes << exercise_attributes(exercise)
        elsif split.matches?(INTERACTIVE_CSS)
          # Interactive
          # Placeholder
          split_attributes << reading_attributes(split, page.url)
        elsif split.matches?(VIDEO_CSS)
          # Video
          # Placeholder
          split_attributes << reading_attributes(split, page.url)
        end

        # Copy the reading content and find the split in the copy
        next_reading = current_reading.dup
        split_copy = next_reading.at_css(SPLIT_CSS)

        # One copy retains the content before the split;
        # the other retains the content after the split
        remove_after(split, current_reading)
        remove_before(split_copy, next_reading)

        # Remove the splits and any empty parents
        recursive_compact(split, current_reading)
        recursive_compact(split_copy, next_reading)

        # Create reading step before current split
        unless current_reading.content.blank?
          split_pages << reading_attributes(current_reading, page.url)
        end

        # Add split contents
        split_pages += split_attributes

        current_reading = next_reading
        split = current_reading.at_css(SPLIT_CSS)
      end

      # Create reading step after all splits
      unless current_reading.content.blank?
        split_pages << reading_attributes(current_reading, page.url)
      end
    end

    split_pages
  end

  def self.distribute_tasks(task_plan:, taskees:)
    title = task_plan.title || 'iReading'
    opens_at = task_plan.opens_at
    due_at = task_plan.due_at || (task_plan.opens_at + 1.week)

    task_step_attributes = split_task_plan_content(task_plan)

    # Assign Tasks to taskees and return the Task array
    taskees.collect do |taskee|
      task = Task.new(task_plan: task_plan,
                      task_type: 'reading',
                      title: title,
                      opens_at: opens_at,
                      due_at: due_at)

      task_step_attributes.each do |attributes|
        step = TaskStep.new(task: task)
        step.tasked = attributes[:tasked_class].new(
          attributes.slice(:url, :title, :content).merge(task_step: step)
        )
        task.task_steps << step
      end

      # Spaced practice
      # TODO: Make a SpacedPracticeStep that does this
      #       right before the user gets the question
      SPACED_PRACTICE_MAP.each do |k_ago, number|
        number.times do
          ex = FillIReadingSpacedPracticeSlot.call(taskee, k_ago)
                                             .outputs[:exercise]

          step = TaskStep.new(task: task)
          step.tasked = TaskedExercise.new(task_step: step,
                                           title: ex.title,
                                           url: ex.url,
                                           content: ex.content)
          task.task_steps << step
        end
      end

      # No group tasks for this assistant
      task.taskings << Tasking.new(task: task, taskee: taskee, user: taskee)

      task.save!
      task
    end
  end

end
