class IReadingAssistant

  # Array of arrays [Events ago, number of spaced practice questions]
  SPACED_PRACTICE_MAP = [[1, 3]]

  # Save as Key Terms and then remove this node
  KEY_TERMS_XPATH = "/html/body/section[contains(concat(' ', @class, ' '), ' key-terms ')]"

  # Save as Summary and then remove this node
  SUMMARY_XPATH = "/html/body/section[contains(concat(' ', @class, ' '), ' summary ')]"

  # Save as Key Equations and then remove this node
  KEY_EQUATIONS_XPATH = "/html/body/section[contains(concat(' ', @class, ' '), ' key-equations ')]"

  # Save as Glossary and then remove this node
  GLOSSARY_XPATH = "/html/body/div[@data-type='glossary']"

  # Remove completely
  REMOVE_XPATH = "//example[contains(concat(' ', @class, ' '), ' snap-lab ')]"

  # Split content on these and create TaskedReadings
  READING_XPATH = '/html/body/section'

  # Split the readings above on these,
  # replace with actual Exercises and create TaskedExercises
  EXERCISE_XPATH = ".//div[@data-type='exercise']"

  # Find the tag to search exercises by from this XPath
  EXERCISE_TAG_XPATH = ".//a[contains(@href, '#ost/api/ex/')]/@href"

  # Extract the tag from the above XPath using this regex
  EXERCISE_TAG_REGEX = /\A#ost\/api\/ex\/([\w-]+)\z/

  # Used to get TaskStep titles
  TITLE_XPATH = "./h1[@data-type='title'] | ./div[@data-type='title']"

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

  def self.distribute_tasks(task_plan:, taskees:)
    title = task_plan.title || 'iReading'
    opens_at = task_plan.opens_at
    due_at = task_plan.due_at || (task_plan.opens_at + 1.week)
    task_step_attributes = []

    task_plan.settings[:page_ids].each do |page_id|
      page = Content::GetPage.call(page_id: page_id).outputs.page
      doc = Nokogiri::HTML(page.content || '')

      # Extract Key Terms
      key_terms = doc.at_xpath(KEY_TERMS_XPATH)
      # TODO: Save Key Terms
      key_terms.try(:remove)

      # Extract Summary
      summary = doc.at_xpath(SUMMARY_XPATH)
      # TODO: Save Summary
      summary.try(:remove)

      # Extract Key Equations
      key_equations = doc.at_xpath(KEY_EQUATIONS_XPATH)
      # TODO: Save Key Equations
      key_equations.try(:remove)

      # Extract Glossary
      glossary = doc.at_xpath(GLOSSARY_XPATH)
      # TODO: Save Glossary
      glossary.try(:remove)

      # Extract Readings
      readings = doc.xpath(READING_XPATH)

      # Record TaskStep attributes
      readings.collect do |reading|
        # Get title
        reading_title = reading.at_xpath(TITLE_XPATH).try(:content) || 'Reading'

        # Initialize current_reading
        current_reading = reading

        # Extract one Exercise
        exercise = current_reading.at_xpath(EXERCISE_XPATH)

        # Split content on Exercises and create TaskSteps
        while !exercise.nil? do
          # Copy the reading content
          next_reading = current_reading.dup
          exercise_copy = next_reading.at_xpath(EXERCISE_XPATH)

          # Split the reading content
          remove_after(exercise, current_reading)
          remove_before(exercise_copy, next_reading)

          # Remove the exercises and any empty parents
          recursive_compact(exercise, current_reading)
          recursive_compact(exercise_copy, next_reading)

          # Create reading step before current exercise
          unless current_reading.content.blank?
            task_step_attributes << { tasked_class: TaskedReading,
                                      title: reading_title,
                                      url: page.url,
                                      content: current_reading.to_html }
          end

          # Create exercise step by tag
          tag_link = exercise.at_xpath(EXERCISE_TAG_XPATH).try(:value)
          tag = EXERCISE_TAG_REGEX.match(tag_link).try(:[], 1)
          ex = OpenStax::Exercises::V1.exercises(tag: tag)['items'].first

          unless ex.nil?
            task_step_attributes << {
              tasked_class: TaskedExercise,
              title: ex.title,
              url: ex.url,
              content: ex.content
            }
          end

          current_reading = next_reading
          exercise = current_reading.at_xpath(EXERCISE_XPATH)
        end

        # Create reading step after all exercises
        unless current_reading.content.blank?
          task_step_attributes << { tasked_class: TaskedReading,
                                    title: reading_title,
                                    url: page.url,
                                    content: current_reading.to_html }
        end
      end
    end

    # Assign Tasks to taskees and return the Task array
    taskees.collect do |taskee|
      task = Task.new(task_plan: task_plan,
                      task_type: 'reading',
                      title: title,
                      opens_at: opens_at,
                      due_at: due_at)

      task_step_attributes.each do |attributes|
        step = TaskStep.new(attributes.slice(:opens_at, :due_at)
                                      .merge(task: task))
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
