# Make sure the Content::Uuid class is loaded to avoid errors in dev/test when threads are spawned
require_dependency './app/subsystems/content/uuid'

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

      course.periods.collect do |period|
        roles = period.active_enrollments.collect{ |ae| ae.student.role }
        [roles, pools, period]
      end
    end

    threads = clue_queries.collect do |roles, pools, period|
      Thread.new do
        OpenStax::Biglearn::V1.get_clues(roles: roles, pools: pools, cache_for: period,
                                         force_cache_miss: true, ignore_answer_times: true)
      end
    end

    threads.each(&:join)
  end

end
