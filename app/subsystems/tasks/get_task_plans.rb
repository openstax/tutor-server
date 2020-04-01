class Tasks::GetTaskPlans
  lev_routine express_output: :plans

  protected

  def exec(owner:, start_at_ntz: nil, end_at_ntz: nil)
    query = Tasks::Models::TaskPlan.without_deleted
                                   .distinct
                                   .joins(:tasking_plans)
                                   .where(owner: owner)
                                   .preload(tasking_plans: :time_zone)

    tgp = Tasks::Models::TaskingPlan.arel_table
    query = query.where(tgp[:due_at_ntz].gteq(start_at_ntz)) unless start_at_ntz.nil?
    query = query.where(tgp[:due_at_ntz].lteq(end_at_ntz)) unless end_at_ntz.nil?

    outputs.plans = query.to_a
  end
end
