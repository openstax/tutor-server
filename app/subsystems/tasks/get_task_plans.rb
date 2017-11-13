class Tasks::GetTaskPlans

  lev_routine express_output: :plans

  protected

  def exec(owner:, start_at_ntz: nil, end_at_ntz: nil)
    query = Tasks::Models::TaskPlan.without_deleted
                                   .joins(:tasking_plans)
                                   .where(owner: owner)
                                   .distinct
                                   .preload(:tasking_plans)
    query = query.where do
      (tasking_plans.opens_at_ntz > start_at_ntz) | (tasking_plans.due_at_ntz > start_at_ntz)
    end unless start_at_ntz.nil?
    query = query.where do
      (tasking_plans.opens_at_ntz < end_at_ntz) | (tasking_plans.due_at_ntz < end_at_ntz)
    end unless end_at_ntz.nil?

    outputs.plans = query.to_a
  end

end
