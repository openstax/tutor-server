class CreateTaskFromTaskPlan

  lev_routine transaction: :no_transaction

  protected

  def exec(task_plan, options={})
    attributes = task_plan.attributes.slice(:opens_at, :due_at, :details)
    attributes[:task_plan] = task_plan
    outputs[:task] = Task.create(attributes)
    transfer_errors_from(outputs[:task], {type: :verbatim}, true)
  end

end
