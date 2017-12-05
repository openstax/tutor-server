# Updates the PeriodCaches, used by the Teacher dashboard Trouble Flag and Performance Forecast
class Tasks::UpdatePeriodCaches
  lev_routine transaction: :read_committed

  protected

  def exec(periods:)
    periods = [periods].flatten

    # Attempt to lock the periods; Skip periods already locked by someone else
    locked_periods = CourseMembership::Models::Period
      .select(:id)
      .where(id: periods.map(&:id))
      .lock('FOR NO KEY UPDATE SKIP LOCKED')
    period_ids = locked_periods.map(&:id)

    # Retry periods that we couldn't lock later
    skipped_periods = periods - locked_periods
    self.class.perform_later(periods: skipped_periods) unless skipped_periods.empty?

    # Stop if we couldn't lock any periods at all
    return if period_ids.empty?

    # Get active students IDs
    student_ids = CourseMembership::Models::Student
      .joins(:latest_enrollment)
      .where(latest_enrollment: { course_membership_period_id: period_ids }, dropped_at: nil)
      .pluck(:id)
    # Stop if no active students
    return if student_ids.empty?

    # Get relevant TaskCaches
    task_caches = Tasks::Models::TaskCache
      .select([ :tasks_task_id, :content_ecosystem_id, :student_ids, :as_toc ])
      .where("\"tasks_task_caches\".\"student_ids\" && ARRAY[#{student_ids.join(', ')}]")
      .preload(
        :ecosystem,
        task: {
          task_plan: { tasking_plans: :target },
          taskings: { role: { student: { latest_enrollment: :period } } }
        }
      )

    # Cache results per period for Teacher dashboard Trouble Flag and Performance Forecast
    grouped_period_task_caches = task_caches.group_by do |task_cache|
      task = task_cache.task
      task_plan = task.task_plan
      preferred_tasking = task.taskings.first
      period = preferred_tasking.role.student.period
      preferred_tasking_plan = task_plan.nil? ? nil : task_plan.tasking_plans.find do |tasking_plan|
        tasking_plan.target == period
      end

      [ period, task_cache.ecosystem, task_plan, preferred_tasking_plan ]
    end

    period_caches = grouped_period_task_caches
      .map do |(period, ecosystem, task_plan, tasking_plan), task_caches|
      build_period_cache(
        period: period,
        ecosystem: ecosystem,
        task_plan: task_plan,
        tasking_plan: tasking_plan,
        task_caches: task_caches
      )
    end

    # Update the PeriodCaches
    no_task_plan_period_caches, task_plan_period_caches = period_caches.partition do |period_cache|
      period_cache.tasks_task_plan_id.nil?
    end
    Tasks::Models::PeriodCache.import task_plan_period_caches, validate: false,
                                                               on_duplicate_key_update: {
      conflict_target: [ :course_membership_period_id, :content_ecosystem_id, :tasks_task_plan_id ],
      columns: [ :opens_at, :due_at, :feedback_at, :student_ids, :as_toc ]
    }
    # activerecord-import surrounds the conflict_target with parens,
    # which is why the next bit of SQL looks slightly broken
    Tasks::Models::PeriodCache.import no_task_plan_period_caches, validate: false,
                                                                  on_duplicate_key_update: {
      columns: [ :opens_at, :due_at, :feedback_at, :student_ids, :as_toc ],
      conflict_target: <<-CONFLICT_SQL.strip_heredoc
        "course_membership_period_id", "content_ecosystem_id") WHERE ("tasks_task_plan_id" IS NULL
      CONFLICT_SQL
    }
  end

  def build_period_cache(period:, ecosystem:, task_plan:, tasking_plan:, task_caches:)
    tocs = task_caches.map(&:as_toc)

    period_bks = tocs.flat_map { |toc| toc[:books] }.group_by { |bk| bk[:title] }
                     .sort.map do |book_location, bks|
      period_chs = bks.flat_map { |bk| bk[:chapters] }.group_by { |ch| ch[:book_location] }
                      .sort.map do |book_location, chs|
        period_pgs = chs.flat_map { |ch| ch[:pages] }.group_by { |pg| pg[:book_location] }
                        .sort.map do |book_location, pgs|
          period_exs = pgs.flat_map { |pg| pg[:exercises] }

          preferred_pg = pgs.first
          {
            id: preferred_pg[:id],
            tutor_uuid: preferred_pg[:tutor_uuid],
            title: preferred_pg[:title],
            book_location: book_location,
            has_exercises: pgs.any? { |pg| pg[:has_exercises] },
            is_spaced_practice: pgs.all? { |pg| pg[:is_spaced_practice] },
            is_intro: pgs.all? { |pg| pg[:is_intro] },
            num_assigned_steps: pgs.map { |pg| pg[:num_assigned_steps] }.reduce(0, :+),
            num_completed_steps: pgs.map { |pg| pg[:num_completed_steps] }.reduce(0, :+),
            num_assigned_exercises: pgs.map { |pg| pg[:num_assigned_exercises] }.reduce(0, :+),
            num_completed_exercises: pgs.map { |pg| pg[:num_completed_exercises] }.reduce(0, :+),
            num_correct_exercises: pgs.map { |pg| pg[:num_correct_exercises] }.reduce(0, :+),
            num_assigned_placeholders: pgs.map { |pg| pg[:num_assigned_placeholders] }
                                          .reduce(0, :+),
            exercises: period_exs
          }
        end

        preferred_ch = chs.first
        {
          id: preferred_ch[:id],
          tutor_uuid: preferred_ch[:tutor_uuid],
          title: preferred_ch[:title],
          book_location: book_location,
          has_exercises: chs.any? { |ch| ch[:has_exercises] },
          is_spaced_practice: chs.all? { |ch| ch[:is_spaced_practice] },
          num_assigned_steps: chs.map { |ch| ch[:num_assigned_steps] }.reduce(0, :+),
          num_completed_steps: chs.map { |ch| ch[:num_completed_steps] }.reduce(0, :+),
          num_assigned_exercises: chs.map { |ch| ch[:num_assigned_exercises] }.reduce(0, :+),
          num_completed_exercises: chs.map { |ch| ch[:num_completed_exercises] }.reduce(0, :+),
          num_correct_exercises: chs.map { |ch| ch[:num_correct_exercises] }.reduce(0, :+),
          num_assigned_placeholders: chs.map { |ch| ch[:num_assigned_placeholders] }.reduce(0, :+),
          pages: period_pgs
        }
      end

      preferred_bk = bks.first
      {
        id: preferred_bk[:id],
        tutor_uuid: preferred_bk[:tutor_uuid],
        title: preferred_bk[:title],
        has_exercises: bks.any? { |bk| bk[:has_exercises] },
        num_assigned_steps: bks.map { |bk| bk[:num_assigned_steps] }.reduce(0, :+),
        num_completed_steps: bks.map { |bk| bk[:num_completed_steps] }.reduce(0, :+),
        num_assigned_exercises: bks.map { |bk| bk[:num_assigned_exercises] }.reduce(0, :+),
        num_completed_exercises: bks.map { |bk| bk[:num_completed_exercises] }.reduce(0, :+),
        num_correct_exercises: bks.map { |bk| bk[:num_correct_exercises] }.reduce(0, :+),
        num_assigned_placeholders: bks.map { |bk| bk[:num_assigned_placeholders] }.reduce(0, :+),
        chapters: period_chs
      }
    end

    preferred_toc = tocs.first
    period_toc = {
      id: preferred_toc[:id],
      tutor_uuid: preferred_toc[:tutor_uuid],
      title: preferred_toc[:title],
      has_exercises: tocs.any? { |toc| toc[:has_exercises] },
      num_assigned_steps: tocs.map { |toc| toc[:num_assigned_steps] }.reduce(0, :+),
      num_completed_steps: tocs.map { |toc| toc[:num_completed_steps] }.reduce(0, :+),
      num_assigned_exercises: tocs.map { |toc| toc[:num_assigned_exercises] }.reduce(0, :+),
      num_completed_exercises: tocs.map { |toc| toc[:num_completed_exercises] }.reduce(0, :+),
      num_correct_exercises: tocs.map { |toc| toc[:num_correct_exercises] }.reduce(0, :+),
      num_assigned_placeholders: tocs.map { |toc| toc[:num_assigned_placeholders] }.reduce(0, :+),
      books: period_bks
    }

    preferred_task_cache = task_caches.first
    Tasks::Models::PeriodCache.new(
      period: period,
      ecosystem: ecosystem,
      task_plan: task_plan,
      opens_at: tasking_plan.try!(:opens_at),
      due_at: tasking_plan.try!(:due_at),
      student_ids: task_caches.flat_map(&:student_ids).uniq,
      as_toc: period_toc
    )
  end
end
