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

    # Retry periods that we couldn't lock later
    skipped_periods = periods - locked_periods
    self.class.perform_later(periods: skipped_periods) unless skipped_periods.empty?

    # Stop if we couldn't lock any periods at all
    return if locked_periods.empty?

    locked_periods.each do |period|
      # Get active students IDs
      student_ids = CourseMembership::Models::Student
        .joins(:latest_enrollment)
        .where(latest_enrollment: { course_membership_period_id: period.id }, dropped_at: nil)
        .pluck(:id)
      # Stop if no active students
      next if student_ids.empty?

      task_cache_query = Tasks::Models::TaskCache
        .joins(:task)
        .where("\"tasks_task_caches\".\"student_ids\" && ARRAY[#{student_ids.join(', ')}]")

      # Get relevant TaskPlans
      task_plan_ids = task_cache_query.distinct.pluck('"tasks_tasks"."tasks_task_plan_id"')
      task_plans = Tasks::Models::TaskPlan.select(:id)
                                          .where(id: task_plan_ids)
                                          .preload(:tasking_plans)
      task_plans << nil if task_plan_ids.any?(&:nil?)

      task_plans.each do |task_plan|
        # Get relevant TaskCaches
        task_caches = task_cache_query.select(
          [ :content_ecosystem_id, :student_ids, :student_names, :as_toc ]
        ).where(task: { tasks_task_plan_id: task_plan.try!(:id) })
        task_caches_by_ecosystem_id = task_caches.group_by(&:content_ecosystem_id)
        ecosystem_ids = task_caches_by_ecosystem_id.keys
        ecosystems = Content::Models::Ecosystem.select(:id).where(id: ecosystem_ids)

        # Cache results per ecosystem for Teacher dashboard Trouble Flag and Performance Forecast
        period_caches = ecosystems.map do |ecosystem|
          task_caches = task_caches_by_ecosystem_id[ecosystem.id]

          build_period_cache(
            period: period,
            ecosystem: ecosystem,
            task_plan: task_plan,
            task_caches: task_caches
          )
        end

        # Update the PeriodCaches
        conflict_target = if task_plan.nil?
          # activerecord-import surrounds the conflict_target with parens,
          # which is why this SQL looks slightly broken
          <<-CONFLICT_SQL.strip_heredoc
            "course_membership_period_id", "content_ecosystem_id")
            WHERE ("tasks_task_plan_id" IS NULL
          CONFLICT_SQL
        else
          [ :course_membership_period_id, :content_ecosystem_id, :tasks_task_plan_id ]
        end
        Tasks::Models::PeriodCache.import period_caches, validate: false, on_duplicate_key_update: {
          columns: [ :opens_at, :due_at, :student_ids, :as_toc ], conflict_target: conflict_target
        }
      end
    end
  end

  def build_period_cache(period:, ecosystem:, task_plan:, task_caches:)
    tocs = task_caches.map do |task_cache|
      toc = task_cache.as_toc
      toc.merge(
        student_ids: task_cache.student_ids,
        student_names: task_cache.student_names,
        books: toc[:books].map do |book|
          book.merge(
            student_ids: task_cache.student_ids,
            student_names: task_cache.student_names,
            chapters: book[:chapters].map do |chapter|
              chapter.merge(
                student_ids: task_cache.student_ids,
                student_names: task_cache.student_names,
                pages: chapter[:pages].map do |page|
                  page.merge(
                    student_ids: task_cache.student_ids,
                    student_names: task_cache.student_names
                  )
                end
              )
            end
          )
        end
      )
    end

    period_bks = tocs.flat_map { |toc| toc[:books] }.group_by { |bk| bk[:title] }
                     .sort.map do |title, bks|
      period_chs = bks.flat_map { |bk| bk[:chapters] }.group_by { |ch| ch[:book_location] }
                      .sort.map do |book_location, chs|
        period_pgs = chs.flat_map { |ch| ch[:pages] }.group_by { |pg| pg[:book_location] }
                        .sort.map do |book_location, pgs|
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
            student_ids: pgs.flat_map { |pg| pg[:student_ids] }.uniq,
            student_names: pgs.flat_map { |pg| pg[:student_names] }.uniq
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
          num_assigned_placeholders: chs.map { |ch| ch[:num_assigned_placeholders] }.reduce(0, :+),          student_ids: chs.flat_map { |ch| ch[:student_ids] }.uniq,
          student_names: chs.flat_map { |ch| ch[:student_names] }.uniq,
          pages: period_pgs
        }
      end

      preferred_bk = bks.first
      {
        id: preferred_bk[:id],
        tutor_uuid: preferred_bk[:tutor_uuid],
        title: title,
        has_exercises: bks.any? { |bk| bk[:has_exercises] },
        num_assigned_steps: bks.map { |bk| bk[:num_assigned_steps] }.reduce(0, :+),
        num_completed_steps: bks.map { |bk| bk[:num_completed_steps] }.reduce(0, :+),
        num_assigned_exercises: bks.map { |bk| bk[:num_assigned_exercises] }.reduce(0, :+),
        num_completed_exercises: bks.map { |bk| bk[:num_completed_exercises] }.reduce(0, :+),
        num_correct_exercises: bks.map { |bk| bk[:num_correct_exercises] }.reduce(0, :+),
        num_assigned_placeholders: bks.map { |bk| bk[:num_assigned_placeholders] }.reduce(0, :+),          student_ids: bks.flat_map { |bk| bk[:student_ids] }.uniq,
        student_names: bks.flat_map { |bk| bk[:student_names] }.uniq,
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
      num_known_location_steps: tocs.map { |toc| toc[:num_known_location_steps] }.reduce(0, :+),
      num_completed_steps: tocs.map { |toc| toc[:num_completed_steps] }.reduce(0, :+),
      num_assigned_exercises: tocs.map { |toc| toc[:num_assigned_exercises] }.reduce(0, :+),
      num_completed_exercises: tocs.map { |toc| toc[:num_completed_exercises] }.reduce(0, :+),
      num_correct_exercises: tocs.map { |toc| toc[:num_correct_exercises] }.reduce(0, :+),
      num_assigned_placeholders: tocs.map { |toc| toc[:num_assigned_placeholders] }.reduce(0, :+),          student_ids: tocs.flat_map { |toc| toc[:student_ids] }.uniq,
      student_names: tocs.flat_map { |toc| toc[:student_names] }.uniq,
      books: period_bks
    }

    tasking_plan = task_plan.nil? ? nil : task_plan.tasking_plans.find { |tp| tp.target == period }
    Tasks::Models::PeriodCache.new(
      period: period,
      ecosystem: ecosystem,
      task_plan: task_plan,
      opens_at: tasking_plan.try!(:opens_at),
      due_at: tasking_plan.try!(:due_at),
      student_ids: period_toc[:student_ids],
      as_toc: period_toc
    )
  end
end
