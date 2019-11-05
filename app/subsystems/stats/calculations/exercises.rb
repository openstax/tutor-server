class Stats::Calculations::Exercises
  lev_routine

  protected

  def exec(stats:, date_range:)
    # TODO don't count ghost students
    %w[reading homework].each do |task_type|
      steps = Tasks::Models::TaskStep.joins(:task)
        .where(:first_completed_at => date_range, task: { task_type: task_type })
      outputs["num_#{task_type}_steps"] = steps.count
    end
  end

end
