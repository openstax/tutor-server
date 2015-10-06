# Make sure the Content::Uuid class is loaded to avoid errors in dev/test when threads are spawned
require_dependency './app/subsystems/content/uuid'

class UpdateClues
  # This value should be, at most, the total number of cores
  # for all Biglearn instances in the current environment (main Biglearn, not workers)
  CONCURRENT_BIGLEARN_REQUESTS = 4

  lev_routine

  protected

  def log(str)
    Rails.logger.info "[CLUe Update] #{str}"
  end

  def exec
    log 'Starting'

    start_time = Time.now

    # Group up clue queries into an array
    clue_queries = Entity::Course.all.preload(
      ecosystems: { chapters: [:all_exercises_pool, { pages: :all_exercises_pool }] },
      periods: { active_enrollments: { student: { role: :profile } } }
    ).flat_map do |course|
      ecosystem_model = course.ecosystems.first
      ecosystem_strategy = Content::Strategies::Direct::Ecosystem.new(ecosystem_model)
      ecosystem = Content::Ecosystem.new(strategy: ecosystem_strategy)

      pools = ecosystem.chapters.collect(&:all_exercises_pool) + \
              ecosystem.pages.collect(&:all_exercises_pool)

      course.periods.flat_map do |period|
        roles = period.active_enrollments.collect{ |ae| ae.student.role }
        [[roles, pools, period]] + roles.collect{ |role| [[role], pools, nil] }
      end
    end

    # Split queries that are too big
    # We do this here instead of relying on the RealClient so we can
    # control exactly the number of concurrent Biglearn requests
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
        queries.collect do |roles, pools, period|
          OpenStax::Biglearn::V1.get_clues(roles: roles, pools: pools, cache_for: period,
                                           force_cache_miss: true, ignore_answer_times: true)
        end
      end
    end

    log "Making #{num_queries} requests to Biglearn using #{threads.size} threads"

    threads.each(&:join)

    log "Done after #{Time.now - start_time} seconds"
  end

end
