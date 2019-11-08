class Stats::Calculations::Assignments
  lev_routine

  protected

  def exec(interval:)
    interval.stats['task_plans'] = Tasks::Models::TaskPlan
      .where(:created_at => interval.range,
             owner_type: CourseProfile::Models::Course.to_s,
             owner_id: interval.courses.populated.map(&:id))
      .count
  end

end
