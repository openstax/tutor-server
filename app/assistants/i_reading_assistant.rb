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

  # Used to get TaskStep titles
  TITLE_XPATH = "./h1[@data-type='title'] | ./div[@data-type='title']"

  def self.schema
    '{
      "type": "object",
      "required": [
        "page_id"
      ],
      "properties": {
        "page_id": {
          "type": "integer"
        }
      },
      "additionalProperties": false
    }'
  end

  def self.distribute_tasks(task_plan:, taskees:)
    # Remove this (move it to tests) once we implement the real client
    OpenStax::Exercises::V1.use_fake_client

    page = Page.find(task_plan.settings[:page_id])
    title = task_plan.title || 'iReading'
    opens_at = task_plan.opens_at
    due_at = task_plan.due_at || (task_plan.opens_at + 1.week)

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
    task_step_attributes = []
    readings.collect do |reading|
      # Get title
      reading_title = reading.at_xpath(TITLE_XPATH).try(:content) || 'Reading'

      # Initialize Content
      remaining_content = reading.content

      # Extract Exercises
      exercises = reading.xpath(EXERCISE_XPATH)

      # Split content on Exercises and create TaskSteps
      exercises.each do |exercise|
        # Split the remaining content
        split_content = remaining_content.split(exercise.content)
        reading_content = split_content.first
        remaining_content = split_content.length > 1 ? \
                              split_content.last : nil

        # Create reading step before current exercise
        unless reading_content.blank?
          task_step_attributes << { tasked_class: TaskedReading,
                                    title: reading_title,
                                    url: page.url,
                                    content: reading_content }
        end

        # Create exercise step
        # TODO: Get info from OpenStax Exercises using ID from CNX
        # For now, use the fake client with random number/version
        number = SecureRandom.hex
        version = SecureRandom.hex
        OpenStax::Exercises::V1.fake_client.add_exercise(number: number,
                                                         version: version)
        ex = JSON.parse(
          OpenStax::Exercises::V1.exercises(number: number, version: version)
        ).first

        task_step_attributes << { tasked_class: TaskedExercise,
                                  title: ex['title'] || 'Exercise',
                                  url: page.url,
                                  content: ex.to_json }
      end

      # Create reading step after all exercises
      unless remaining_content.blank?
        task_step_attributes << { tasked_class: TaskedReading,
                                  title: reading_title,
                                  url: page.url,
                                  content: remaining_content }
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
        step = TaskStep.new(attributes.except(:tasked_class)
                                      .merge(task: task))
        step.tasked = attributes[:tasked_class].new(task_step: step)
        task.task_steps << step
      end

      # Spaced practice
      SPACED_PRACTICE_MAP.each do |k_ago, number|
        number.times do
          #ex = IReadingSpacedPracticeSlotFiller.call(taskee, k_ago)
          #step = TaskStep.new(task: task,
          #                    tasked: TaskedExercise.new,
          #                    title: ex['title'] || 'Exercise',
          #                    url: ex['url'] || page.url,
          #                    content: ex.to_json)
          #task.task_steps << step
        end
      end

      # No group tasks for this assistant
      task.taskings << Tasking.new(task: task, taskee: taskee, user: taskee)

      task.save!
      task
    end
  end

end
