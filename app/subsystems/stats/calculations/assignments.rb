class Stats::Calculations::Assignments
  lev_routine

  protected

  def exec(interval:)
    plans = Tasks::Models::TaskPlan.where(
      :created_at => interval.range,
      course_profile_course_id: interval.courses.populated.map(&:id)
    )

    ['reading', 'homework'].each do |type|
      interval.stats["#{type}_task_plans"] = plans.dup
        .where(type: type).count
    end
  end

end
