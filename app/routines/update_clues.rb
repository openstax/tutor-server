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

    # Make a list of all exercises being considered according to the :type parameter
    all_exercise_models = case type
    when :all
      # All exercises ever assigned are valid
      Content::Models::Exercise.joins(:tasked_exercises)
    when :recent
      # Recently worked exercises are valid
      recent_cutoff = start_time - RECENT_EXERCISE_DURATION

      Content::Models::Exercise
        .joins(tasked_exercises: :task_step)
        .where{ tasked_exercises.task_step.last_completed_at > recent_cutoff }
    else
      raise ArgumentError, ':type must be either :all or :recent', caller
    end

    all_exercises = all_exercise_models.collect do |exercise_model|
      strategy = Content::Strategies::Direct::Exercise.new(exercise_model)
      Content::Exercise.new(strategy: strategy)
    end

    # Collect CLUe queries for the most recent ecosystem in each course
    clue_queries = Entity::Course.all.preload(
      periods: { active_enrollments: { student: { role: :profile } } }
    ).flat_map do |course|
      # Get the Ecosystems map
      ecosystems_map = run(:get_map, course: course).outputs.ecosystems_map

      # Map all the exercises being considered to pages in the current ecosystem
      # Clues are always requested based on the pages of the current ecosystem
      pages = ecosystems_map.map_exercises_to_pages(exercises: all_exercises).values
      chapters = pages.collect(&:chapter).uniq

      pools = chapters.collect(&:all_exercises_pool) + pages.collect(&:all_exercises_pool)

      next if pools.empty?

      course.periods.flat_map do |period|
        roles = period.active_enrollments.collect{ |ae| ae.student.role }
        [[roles, pools, period]] + roles.collect{ |role| [[role], pools, role] }
      end
    end.compact

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
      pools.each_slice(slice_size).collect do |sliced_pools|
        [roles, sliced_pools, query.third]
      end
    end

    num_queries = split_clue_queries.size
    slice_size = (num_queries/CONCURRENT_BIGLEARN_REQUESTS.to_f).ceil

    threads = split_clue_queries.each_slice(slice_size).collect do |queries|
      Thread.new do
        queries.collect do |roles, pools, cache_for|
          OpenStax::Biglearn::V1.get_clues(roles: roles, pools: pools,
                                           cache_for: cache_for, force_cache_miss: true)
        end
      end
    end

    log type, "Making #{num_queries} requests to Biglearn using #{threads.size} threads"

    threads.each(&:join)

    log type, "Done after #{Time.now - start_time} seconds"
  end

end
