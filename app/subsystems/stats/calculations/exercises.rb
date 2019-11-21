class Stats::Calculations::Exercises
  lev_routine

  protected

  def exec(interval:)
    %w[reading exercise].each do |task_type|
      interval.stats["#{task_type}_steps"] = Tasks::Models::TaskStep
        .joins(task: :task_plan)
        .where(:first_completed_at => interval.range,
               tasked_type: "Tasks::Models::Tasked#{task_type.classify}",
               task: { task_plan: {
                 owner_type: CourseProfile::Models::Course.to_s,
                 owner_id: interval.courses.populated.map(&:id)
               } })
        .count
    end

    interval.stats["practice_steps"] = Tasks::Models::TaskStep
      .joins(:task)
      .where(
        :first_completed_at => interval.range,
        task: { task_type: %w[practice_worst_topics page_practice] }
      )
      .count

    nudge_stats = Tasks::Models::TaskedExercise
      .joins(task_step: :task)
      .where("coalesce(jsonb_array_length(response_validation->'attempts'), 0) > 0")
      .select(
      "coalesce(sum((case when jsonb_array_length(response_validation->'attempts') > 0 then 1 else 0 end)), 0) as nudge_calculated,
      coalesce(sum((case when (response_validation->'attempts'->0->'valid') = 'true' then 0 else 1 end)), 0) as nudge_initially_invalid,
      coalesce(sum((case when (response_validation->'attempts'->1->'valid') = 'true' then 1 else 0 end)), 0) as nudge_retry_correct"
    ).all[0].as_json(except: :id)

    interval.stats.merge!(nudge_stats)
  end
end
