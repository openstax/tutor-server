class Stats::Calculations::Exercises
  lev_routine

  protected

  def exec(interval:)
    %w[reading exercise].each do |task_type|
      interval.stats["#{task_type}_steps"] = Tasks::Models::TaskStep
        .where(:first_completed_at => interval.range,
               tasked_type: "Tasks::Models::Tasked#{task_type.classify}")
        .count
    end
  end

end
