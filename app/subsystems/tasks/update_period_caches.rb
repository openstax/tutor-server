# Updates the PeriodCaches, used by the Teacher dashboard Trouble Flag and Performance Forecast
class Tasks::UpdatePeriodCaches
  lev_routine active_job_enqueue_options: { queue: :low_priority }, transaction: :read_committed

  protected

  def exec(periods:, force: false)
    periods = [periods].flatten
    periods.each do |period|
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
      task_plan_query = task_cache_query.dup
      task_plan_query = task_plan_query.where(is_cached_for_period: false) unless force
      task_plan_ids = task_plan_query.distinct.pluck('"tasks_tasks"."tasks_task_plan_id"')
      task_plans = Tasks::Models::TaskPlan.select(:id)
                                          .where(id: task_plan_ids)
                                          .preload(:tasking_plans)
      task_plans << nil if task_plan_ids.any?(&:nil?)

      task_plans.each do |task_plan|
        # Get and lock relevant TaskCaches
        task_caches = task_cache_query.select(
          [
            :id,
            :content_ecosystem_id,
            :student_ids,
            :student_names,
            :as_toc,
            :is_cached_for_period
          ]
        )
        .where(task: { tasks_task_plan_id: task_plan.try!(:id) })
        .lock('FOR NO KEY UPDATE OF "tasks_task_caches"')
        .to_a
        # Recheck if all task_caches have already been added to the PeriodCache
        # (since we hadn't locked them before)
        next if !force && task_caches.all?(&:is_cached_for_period)

        task_caches_by_ecosystem_id = task_caches.group_by(&:content_ecosystem_id)
        ecosystem_ids = task_caches_by_ecosystem_id.keys
        ecosystems = Content::Models::Ecosystem.select(:id).where(id: ecosystem_ids)

        # Cache results per ecosystem for Teacher dashboard Trouble Flag and Performance Forecast
        period_caches = ecosystems.map do |ecosystem|
          period_task_caches = task_caches_by_ecosystem_id[ecosystem.id]

          build_period_cache(
            period: period,
            ecosystem: ecosystem,
            task_plan: task_plan,
            task_caches: period_task_caches
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

        # Mark the TaskCaches as cached for period
        Tasks::Models::TaskCache.where(id: task_caches.map(&:id), is_cached_for_period: false)
                                .update_all(is_cached_for_period: true)
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
            num_assigned_steps: pgs.sum { |pg| pg[:num_assigned_steps] },
            num_completed_steps: pgs.sum { |pg| pg[:num_completed_steps] },
            num_assigned_exercises: pgs.sum { |pg| pg[:num_assigned_exercises] },
            num_completed_exercises: pgs.sum { |pg| pg[:num_completed_exercises] },
            num_correct_exercises: pgs.sum { |pg| pg[:num_correct_exercises] },
            num_assigned_placeholders: pgs.sum { |pg| pg[:num_assigned_placeholders] },
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
          num_assigned_steps: chs.sum { |ch| ch[:num_assigned_steps] },
          num_completed_steps: chs.sum { |ch| ch[:num_completed_steps] },
          num_assigned_exercises: chs.sum { |ch| ch[:num_assigned_exercises] },
          num_completed_exercises: chs.sum { |ch| ch[:num_completed_exercises] },
          num_correct_exercises: chs.sum { |ch| ch[:num_correct_exercises] },
          num_assigned_placeholders: chs.sum { |ch| ch[:num_assigned_placeholders] },
          student_ids: chs.flat_map { |ch| ch[:student_ids] }.uniq,
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
        num_assigned_steps: bks.sum { |bk| bk[:num_assigned_steps] },
        num_completed_steps: bks.sum { |bk| bk[:num_completed_steps] },
        num_assigned_exercises: bks.sum { |bk| bk[:num_assigned_exercises] },
        num_completed_exercises: bks.sum { |bk| bk[:num_completed_exercises] },
        num_correct_exercises: bks.sum { |bk| bk[:num_correct_exercises] },
        num_assigned_placeholders: bks.sum { |bk| bk[:num_assigned_placeholders] },
        student_ids: bks.flat_map { |bk| bk[:student_ids] }.uniq,
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
      num_assigned_steps: tocs.sum { |toc| toc[:num_assigned_steps] },
      num_assigned_known_location_steps: tocs.sum do |toc|
        toc[:num_assigned_known_location_steps] || toc[:num_assigned_steps]
      end,
      num_completed_steps: tocs.sum { |toc| toc[:num_completed_steps] },
      num_completed_known_location_steps: tocs.sum do |toc|
        toc[:num_completed_known_location_steps] || toc[:num_completed_steps]
      end,
      num_assigned_exercises: tocs.sum { |toc| toc[:num_assigned_exercises] },
      num_completed_exercises: tocs.sum { |toc| toc[:num_completed_exercises] },
      num_correct_exercises: tocs.sum { |toc| toc[:num_correct_exercises] },
      num_assigned_placeholders: tocs.sum { |toc| toc[:num_assigned_placeholders] },
      student_ids: tocs.flat_map { |toc| toc[:student_ids] }.uniq,
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
