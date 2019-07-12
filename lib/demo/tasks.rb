require_relative 'base'
require_relative 'config/course'

# Adds students to the course periods, assigns Sets up the periods and students for a course
# and then generates activity for them
class Demo::Tasks < Demo::Base
  lev_routine

  disable_automatic_lev_transactions

  uses_routine DistributeTasks

  protected

  def exec(config: :all, random_seed: nil)
    set_random_seed(random_seed)

    in_parallel(Demo::Config::Course[config], transaction: true) do |course_configs, initial_index|
      course_configs.each do |course_config|
        course = find_demo_course_by_name!(course_config.course_name)

        # Clear any leftover data in the course
        Tasks::Models::TaskPlan.where(owner: course).delete_all

        assignments = course_config.assignments + get_auto_assignments(course_config).flatten
        assignments.each { |assignment| create_assignment(course_config, assignment, course) }
      end
    end

    wait_for_parallel_completion
  end


  def get_ecosystem(course:)
    ecosystem_model = course.ecosystem
    return if ecosystem_model.nil?

    strategy = Content::Strategies::Direct::Ecosystem.new(ecosystem_model)
    Content::Ecosystem.new(strategy: strategy)
  end

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.find_by(tasks_task_plan_type: task_plan_type).assistant
  end

  def lookup_pages(book:, book_locations:)
    book_locations = (book_locations.first.is_a?(Array) ? \
                      book_locations : [book_locations]).compact

    book.pages.to_a.select { |page| book_locations.include?(page.book_location) }
  end

  def assign_ireading(course:, book_locations:, title:)
    ecosystem = get_ecosystem(course: course)
    book = ecosystem.books.first
    pages = lookup_pages(book: book, book_locations: book_locations)

    raise "No pages to assign" if pages.blank?

    Tasks::Models::TaskPlan.new(
      title: title,
      owner: course,
      is_preview: true,
      content_ecosystem_id: ecosystem.id,
      type: 'reading',
      assistant: get_assistant(course: course, task_plan_type: 'reading'),
      settings: { page_ids: pages.map { |page| page.id.to_s } }
    )
  end

  def assign_homework(course:, book_locations:, num_exercises:, title:)
    ecosystem = get_ecosystem(course: course)
    book = ecosystem.books.first
    pages = lookup_pages(book: book, book_locations: book_locations)
    pools = ecosystem.homework_core_pools(pages: pages)
    exercises = pools.map(&:exercises).flatten.uniq.shuffle(random: randomizer)
    exercise_ids = exercises.take(num_exercises).map { |e| e.id.to_s }

    raise "No exercises to assign (using #{OpenStax::Exercises::V1.server_url})" \
      if exercise_ids.blank?

    Tasks::Models::TaskPlan.new(
      title: title,
      owner: course,
      is_preview: true,
      content_ecosystem_id: ecosystem.id,
      type: 'homework',
      assistant: get_assistant(course: course, task_plan_type: 'homework'),
      settings: {
        page_ids: pages.map { |page| page.id.to_s},
        exercise_ids: exercise_ids,
        exercises_count_dynamic: 4
      }
    )
  end

  def add_tasking_plan(task_plan:, to:, opens_at:, due_at:, message: nil)
    targets = [to].flatten
    targets.each do |target|
      task_plan.tasking_plans << Tasks::Models::TaskingPlan.new(
        target: target,
        task_plan: task_plan,
        opens_at: opens_at,
        due_at: due_at,
        time_zone: task_plan.owner.time_zone
      )
    end
    task_plan.save!
  end

  def step_code(step)
    case step.tasked
    when Tasks::Models::TaskedExercise
      'e'
    when Tasks::Models::TaskedReading
      'r'
    when Tasks::Models::TaskedVideo
      'v'
    when Tasks::Models::TaskedInteractive
      'i'
    when Tasks::Models::TaskedPlaceholder
      'p'
    else
      'u'
    end
  end

  def print_task(task:)
    types = task.task_steps.map do |step|
      group_code = if step.unknown_group?
        'u'
      elsif step.core_group?
        'c'
      elsif step.spaced_practice_group?
        's'
      elsif step.personalized_group?
        'p'
      else
        'o'
      end

      "#{group_code}#{step.id}#{step_code(step)}"
    end
    codes = task.task_steps.map { |step| step_code(step) }
    "Task #{task.id} / #{task.task_type}\n#{codes.join(', ')}\n#{types.join(' ')}"
  end

  def distribute_tasks(task_plan:)
    run(DistributeTasks, task_plan: task_plan).outputs.tasks.tap do |tasks|
      log { "Assigned #{task_plan.type} #{tasks.count} times" }
      log { "One task looks like: #{print_task(task: tasks.first)}" } if tasks.any?
    end
  end

  def create_assignment(course_config, assignment, course)
    log do
      "Creating #{assignment.type} #{assignment.title} for course #{course.name} (id: #{course.id})"
    end

    task_plan = if assignment.type == 'reading'
                  assign_ireading(course: course,
                                  book_locations: assignment.book_locations,
                                  title: assignment.title)
                else
                  assign_homework(course: course,
                                  book_locations: assignment.book_locations,
                                  title: assignment.title,
                                  num_exercises: assignment.num_exercises)
                end

    assignment.periods.each do |period|
      log { "  Adding tasking plan for period #{period.id}" }
      course_period = course.periods.where(name: course_config.get_period(period.id).name).first!
      add_tasking_plan(task_plan: task_plan,
                       to: course_period,
                       opens_at: period.opens_at,
                       due_at: period.due_at)

      ShortCode::Create[task_plan.to_global_id.to_s]
    end

    assignment.id = task_plan.id

    # Draft plans do not undergo distribution
    if assignment.draft
      log { "  Is a draft, skipping distributing" }
    else
      log { "  Distributing tasks" }
      distribute_tasks(task_plan: task_plan)
    end
  end
end
