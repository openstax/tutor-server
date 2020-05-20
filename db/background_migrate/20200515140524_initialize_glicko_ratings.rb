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

    tt = Tasks::Models::Task.arel_table

    last_worked_at = STORE.read 'last_worked_at'

    loop do
      tasks = Tasks::Models::Task.transaction do
        tasks = Tasks::Models::Task
          .where(tt[:completed_exercise_steps_count].gt(0))
          .where('"steps_count" <= "completed_steps_count"')
          .order(:last_worked_at)
          .preload(taskings: { role: [ { student: :period }, { teacher_student: :period } ] })

        tasks = tasks.where(tt[:last_worked_at].gteq(last_worked_at)) unless last_worked_at.nil?

        tasks = tasks.first(LIMIT)

        next tasks if tasks.empty?

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

        last_worked_at = tasks.last.last_worked_at
        STORE.write 'last_worked_at', last_worked_at

        tasks
      end

      break if tasks.empty?
    end

    max_due_at = STORE.read 'max_due_at'

    loop do
      tasks = Tasks::Models::Task.transaction do
        tasks = Tasks::Models::Task
          .where(tt[:completed_exercise_steps_count].gt(0))
          .where('"steps_count" > "completed_steps_count"')
          .where.not(due_at_ntz: nil)
          .order(:due_at_ntz)
          .preload(taskings: { role: [ { student: :period }, { teacher_student: :period } ] })

        tasks = tasks.where(tt[:due_at_ntz].gteq(max_due_at)) unless max_due_at.nil?

        tasks = tasks.first(LIMIT)

        next tasks if tasks.empty?

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

        tasks
      end

      break if tasks.empty?
    end

    STORE.delete 'last_worked_at'
    STORE.delete 'max_due_at'
  end

  def down
  end
end
