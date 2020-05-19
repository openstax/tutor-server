class InitializeGlickoRatings < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  include Ratings::Concerns::RatingJobs

  redis_secrets = Rails.application.secrets.redis
  # STORE needs to be an ActiveSupport::Cache::RedisStore to support TTL
  STORE = ActiveSupport::Cache::RedisStore.new(
    url: redis_secrets[:url],
    namespace: 'migration',
    expires_in: 1.year
  )
  LIMIT = 1000

  def up
    current_time = Time.current

    max_due_at = STORE.read 'max_due_at'

    loop do
      Tasks::Models::Task.transaction do
        tasks = Tasks::Models::Task.preload(
          taskings: { role: [ { student: :period }, { teacher_student: :period } ] }
        ).order(:due_at_ntz)

        tasks = tasks.where(Tasks::Models::Task.arel_table[:due_at_ntz].gt(max_due_at)) \
          unless max_due_at.nil?

        tasks = tasks.first(LIMIT)

        break if tasks.empty?

        tasks.each do |task|
          role = task.taskings.first.role
          period = role.course_member.period

          perform_rating_jobs_later(
            task: task,
            role: role,
            period: period,
            current_time: current_time,
            queue: 'migration'
          )
        end

        max_due_at = tasks.last.due_at_ntz
        STORE.write 'max_due_at', max_due_at
      end
    end

    STORE.delete 'max_due_at'
  end

  def down
  end
end
