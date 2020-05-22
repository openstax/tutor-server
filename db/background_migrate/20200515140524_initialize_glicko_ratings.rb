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
  LIMIT = 1100

  def up
    cc = CourseProfile::Models::Course.arel_table
    active_preview_course_ids = CourseProfile::Models::Course
      .where(preview_claimed_at: nil)
      .or(CourseProfile::Models::Course.where(cc[:ends_at].gt(Time.current)))
      .where(is_preview: true)
      .pluck(:id)
    migrate_course_tasks course_ids: active_preview_course_ids, key: 'preview'

    other_course_ids =  CourseProfile::Models::Course.pluck(:id) - active_preview_course_ids
    migrate_course_tasks course_ids: other_course_ids, key: 'other'
  end

  def migrate_course_tasks(course_ids:, key:)
    current_time = Time.current

    tt = Tasks::Models::Task.arel_table

    last_worked_at_key = "#{key}_last_worked_at"
    last_worked_at = STORE.read last_worked_at_key

    loop do
      tasks = Tasks::Models::Task.transaction do
        tasks = Tasks::Models::Task
          .where(course_profile_course_id: course_ids)
          .where(tt[:completed_exercise_steps_count].gt(0))
          .where('"steps_count" <= "completed_steps_count"')
          .where.not(last_worked_at: nil)
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
        STORE.write last_worked_at_key, last_worked_at

        tasks
      end

      break if tasks.size < LIMIT
    end

    max_due_at_key = "#{key}_max_due_at"
    max_due_at = STORE.read max_due_at_key

    loop do
      tasks = Tasks::Models::Task.transaction do
        tasks = Tasks::Models::Task
          .where(course_profile_course_id: course_ids)
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
        STORE.write max_due_at_key, max_due_at

        tasks
      end

      break if tasks.size < LIMIT
    end
  end

  def down
    STORE.delete 'preview_last_worked_at'
    STORE.delete 'preview_max_due_at'

    STORE.delete 'other_last_worked_at'
    STORE.delete 'other_max_due_at'
  end
end
