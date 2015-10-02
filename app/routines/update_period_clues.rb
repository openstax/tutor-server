# Make sure the Content::Uuid class is loaded to avoid errors in dev/test when threads are spawned
require_dependency 'app/subsystems/content/uuid'

class UpdatePeriodClues
  lev_routine

  protected

  def exec
    clue_queries = Entity::Course.all.preload(
      ecosystems: { chapters: [:all_exercises_pool, { pages: :all_exercises_pool }] },
      periods: { active_enrollments: { student: { role: :profile } } }
    ).flat_map do |course|
      ecosystem_model = course.ecosystems.first
      ecosystem_strategy = Content::Strategies::Direct::Ecosystem.new(ecosystem_model)
      ecosystem = Content::Ecosystem.new(strategy: ecosystem_strategy)

      pools = ecosystem.chapters.collect(&:all_exercises_pool) + \
              ecosystem.pages.collect(&:all_exercises_pool)

      course.periods.collect{ |period| [period, pools] }
    end

    threads = clue_queries.collect do |period, pools|
      Thread.new do
        OpenStax::Biglearn::V1.get_clues(pools: pools, period: period,
                                         force_cache_miss: true, ignore_answer_times: true)
      end
    end

    threads.each(&:join)
  end

end
