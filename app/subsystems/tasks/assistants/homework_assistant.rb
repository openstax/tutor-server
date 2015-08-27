class Tasks::Assistants::HomeworkAssistant

  def self.schema
    '{
      "type": "object",
      "required": [
        "exercise_ids",
        "exercises_count_dynamic"
      ],
      "properties": {
        "exercise_ids": {
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "exercises_count_dynamic": {
          "type": "integer",
          "minimum": 2,
          "maximum": 4
        },
        "page_ids": {
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

    collect_exercises

    @tag_exercise = {}
    @exercise_pages = {}
    @page_pools = {}
    @pool_exercises = {}
  end

  def build_tasks
    @taskees.collect do |taskee|
      build_homework_task(
        taskee:       taskee,
        exercises:    @exercises
      ).entity_task
    end
  end

  protected

  def collect_exercises
    @exercise_ids = @task_plan.settings['exercise_ids']
    raise "No exercises selected" if @exercise_ids.blank?

    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(@task_plan.ecosystem)
    @ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)

    @exercises = @ecosystem.exercises_by_ids(@exercise_ids)
  end

  def build_homework_task(taskee:, exercises:)
    task = build_task

    add_core_steps!(task: task, exercises: exercises)
    add_spaced_practice_exercise_steps!(task: task, taskee: taskee)
    add_personalized_exercise_steps!(task: task, taskee: taskee)
  end

  def build_task
    title    = @task_plan.title || 'Homework'
    description = @task_plan.description

    Tasks::BuildTask[
      task_plan:   @task_plan,
      task_type:   :homework,
      title:       title,
      description: description
    ]
  end

  def add_core_steps!(task:, exercises:)
    exercises.each do |exercise|
      step = add_exercise_step(task: task, exercise: exercise)
      step.group_type = :core_group
      step.add_related_content(exercise.page.related_content)
    end

    task
  end

  def add_exercise_step(task:, exercise:)
    step = Tasks::Models::TaskStep.new(task: task)
    TaskExercise[task_step: step, exercise: exercise]
    task.task_steps << step
    step
  end

  def add_spaced_practice_exercise_steps!(task:, taskee:)
    homework_history = get_taskee_homework_history(task: task, taskee: taskee)
    #puts "taskee: #{taskee.inspect}"
    #puts "ireading history:  #{homework_history.inspect}"

    exercise_history = GetExerciseHistory[ecosystem: @ecosystem, entity_tasks: homework_history]
    #puts "exercise history:  #{exercise_history.map(&:uid).sort}"

    exercise_pools = get_exercise_pools(exercise_history: exercise_history)
    #puts "exercise pools:  #{exercise_pools.map{|ep| ep.map(&:uid).sort}}}"

    flat_history = exercise_history.flatten

    num_spaced_practice_exercises = get_num_spaced_practice_exercises
    self.class.k_ago_map(num_spaced_practice_exercises).each do |k_ago, number|
      break if k_ago >= exercise_pools.count

      candidate_exercises = (exercise_pools[k_ago] - flat_history).uniq
      break if candidate_exercises.size < number

      number.times do
        #puts "candidate_exercises: #{candidate_exercises.map(&:uid).sort}"
        #puts "exercise history:    #{exercise_history.map(&:uid).sort}"

        chosen_exercise = candidate_exercises.to_a.sample # .first to aid debug
        #puts "chosen exercise:     #{chosen_exercise.uid}"

        candidate_exercises.delete(chosen_exercise)
        flat_history.push(chosen_exercise)

        related_content = chosen_exercise.page.related_content

        step = add_exercise_step(task: task, exercise: chosen_exercise)
        step.group_type = :spaced_practice_group

        step.add_related_content(related_content)
      end
    end

    task
  end

  # Get the student's homework assignments
  def get_taskee_homework_history(task:, taskee:)
    tasks = taskee.taskings.preload(task: {task: {task_steps: :tasked}})
                           .collect{ |tasking| tasking.task.task }

    homework_history = tasks.select{|tt| tt.homework?}
                            .reject{|tt| tt == task}
                            .sort_by{|tt| [tt.due_at, tt.task_plan.created_at]}
                            .push(task)
                            .reverse
                            .collect{|tt| tt.entity_task}

    homework_history
  end

  # Get the page for each exercise in the student's assignments
  # From each page, get the pool of dynamic homework problems
  def get_exercise_pools(exercise_history:)
    exercise_pools = exercise_history.collect do |exercises|
      pages = exercises.collect{ |ex| get_exercise_pages(ex) }
      pools = get_page_pools(pages)
      pools.collect{ |pool| get_pool_exercises(pool) }.flatten
    end
  end

  def get_num_spaced_practice_exercises
    exercises_count_dynamic = @task_plan[:settings]['exercises_count_dynamic']
    num_spaced_practice_exercises = [0, exercises_count_dynamic-1].max
    num_spaced_practice_exercises
  end

  def self.k_ago_map(num_spaced_practice_exercises)
    ## Entries in the list have the form:
    ##   [from-this-many-events-ago, choose-this-many-exercises]
    case num_spaced_practice_exercises
    when 0
      []
    when 1
      [ [2,1] ]
    when 2
      [ [2,1], [4,1] ]
    when 3
      [ [2,2], [4,1] ]
    when 4
      [ [2,2], [4,2] ]
    else
      raise "could not determine k-ago map for num_spaced_practice_exercises=#{num_spaced_practice_exercises}"
    end
  end

  def add_personalized_exercise_steps!(task:, taskee:)
    task.personalized_placeholder_strategy = Tasks::PlaceholderStrategies::HomeworkPersonalized.new \
      if self.class.num_personalized_exercises > 0

    self.class.num_personalized_exercises.times do
      task_step = Tasks::Models::TaskStep.new(task: task)
      tasked_placeholder = Tasks::Models::TaskedPlaceholder.new(task_step: task_step)
      tasked_placeholder.placeholder_type = :exercise_type
      task_step.tasked = tasked_placeholder
      task_step.group_type = :personalized_group
      task.task_steps << task_step
    end

    task
  end

  def self.num_personalized_exercises
    1
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

end
