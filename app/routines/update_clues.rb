# Make sure the Content::Uuid class is loaded to avoid errors in dev/test when threads are spawned
require_dependency './app/subsystems/content/uuid'

class UpdateClues
  # This value should be, at most, the total number of cores
  # for all Biglearn instances in the current environment (not including workers)
  # Default is 4 to match production
  CONCURRENT_BIGLEARN_REQUESTS = 4

  # How long to consider worked exercises to be "recent"
  # Default is 4 minutes because "fast" sparfa runs every 3 minutes, plus 1 minute slack
  RECENT_EXERCISE_DURATION = 4.minutes

  lev_routine

  uses_routine GetCourseEcosystemsMap, as: :get_map

  protected

  def log(type, str)
    Rails.logger.info "[CLUe Update #{type.to_s.capitalize}] #{str}"
  end

  def exec(type:)
    log type, 'Starting'

    start_time = Time.now

    tasked_exercise_relation = Tasks::Models::TaskedExercise.joins(:task_step).preload(
      [ { task_step: { task: { taskings: :role } } }, :exercise ]
    )

    # Make a list of all tasked exercises being considered according to the :type parameter
    worked_tasked_exercises = case type
    when :all
      # All tasked exercises are considered for the CLUe update
      tasked_exercise_relation
    when :recent
      # Recently worked tasked exercises are considered for the CLUe update
      recent_cutoff = start_time - RECENT_EXERCISE_DURATION
      tasked_exercise_relation.where{ task_step.last_completed_at > recent_cutoff }
    else
      raise ArgumentError, ':type must be either :all or :recent', caller
    end

    role_ids_to_worked_exercises_map = worked_tasked_exercises
                                         .find_each.each_with_object({}) do |tasked_exercise, hash|
      model = tasked_exercise.exercise
      strategy = Content::Strategies::Direct::Exercise.new(model)
      exercise = Content::Exercise.new(strategy: strategy)

      tasked_exercise.task_step.task.taskings.map(&:role).each do |role|
        hash[role.id] ||= []
        hash[role.id] << exercise
      end
    end

    # Collect CLUe queries for the most recent ecosystem in each non-CC course
    clue_queries = Entity::Course.joins(:profile)
                                 .where(profile: {is_concept_coach: false})
                                 .preload(
      periods: { active_enrollments: { student: { role: :profile } } }
    ).flat_map do |course|
      # Get all student roles in the course
      course_roles = course.periods.flat_map do |period|
        period.active_enrollments.map{ |ae| ae.student.role }
      end

      # Get all exercises worked by students in the course
      course_worked_exercises = course_roles.flat_map do |role|
        role_ids_to_worked_exercises_map[role.id]
      end

      # Skip if no exercises got worked in the course
      next [] if course_worked_exercises.empty?

      # Get the Ecosystems map
      ecosystems_map = run(:get_map, course: course).outputs.ecosystems_map

      # Map all worked exercises to pages in the current ecosystem
      # Clues are always requested based on the current ecosystem
      worked_exercise_id_to_page_map = ecosystems_map.map_exercises_to_pages(
        exercises: course_worked_exercises
      )

      course.periods.flat_map do |period|
        # Get all students in the period
        period_roles = period.active_enrollments.map{ |ae| ae.student.role }

        # Make a map of who worked what pools
        period_roles_to_worked_pools_map = period_roles.each_with_object({}) do |role, hash|
          worked_exercises = role_ids_to_worked_exercises_map[role.id]

          # Skip if we didn't work anything
          next if worked_exercises.nil?

          worked_pages = worked_exercises.map do |exercise|
            worked_exercise_id_to_page_map[exercise.id]
          end.compact.uniq

          # Skip if we worked something, but it somehow did not map to the current ecosystem
          next if worked_pages.empty?

          worked_chapters = worked_pages.map(&:chapter).uniq
          worked_pools = worked_chapters.map(&:all_exercises_pool) + \
                         worked_pages.map(&:all_exercises_pool)
          hash[role] = worked_pools
        end

        # All worked pools are included in the period-wide CLUe update
        period_worked_pools = period_roles_to_worked_pools_map.values.flatten.uniq

        # No need to update period CLUes if nobody in the period worked any problems
        next [] if period_worked_pools.empty?

        # Update CLUes for the entire period, plus CLUes for individual students that did work
        [[period_roles, period_worked_pools, period]] + \
        period_roles_to_worked_pools_map.map{ |role, pools| [[role], pools, role] }
      end
    end

    # Split queries that are too big
    # We do this here instead of relying on the RealClient so we can
    # control exactly the number of concurrent Biglearn requests to avoid timeouts
    max_query_size = OpenStax::Biglearn::V1::RealClient::CLUE_MAX_POOL_STUDENT_PRODUCT
    split_clue_queries = clue_queries.flat_map do |query|
      roles = query.first
      pools = query.second
      num_roles = roles.size
      num_pools = pools.size

      query_size = num_roles*num_pools
      next [query] if query_size <= max_query_size

      slice_size = [max_query_size/num_roles, 1].max
      pools.each_slice(slice_size).map do |sliced_pools|
        [roles, sliced_pools, query.third]
      end
    end

    num_queries = split_clue_queries.size

    if num_queries > 0
      slice_size = (num_queries/CONCURRENT_BIGLEARN_REQUESTS.to_f).ceil

      threads = split_clue_queries.each_slice(slice_size).map do |queries|
        Thread.new do
          queries.map do |roles, pools, cache_for|
            OpenStax::Biglearn::V1.get_clues(roles: roles, pools: pools,
                                             cache_for: cache_for, force_cache_miss: true)
          end
        end
      end

      log type, "Making #{num_queries} requests to Biglearn using #{threads.size} threads"

      threads.each(&:join)
    end

    log type, "Done after #{Time.now - start_time} seconds"
  end

end
