class ShortCode::FindTaskPlanShortCode
  lev_routine express_output: :short_code
  uses_routine FindShortCode,
               translations: { outputs: { type: :verbatim } },
               as: :find_short_code

  protected

  def exec(task_plan_id)
    gid = GlobalID::URI::GID.build(
      app: GlobalID.app, model_name: 'Tasks::Models::TaskPlan', model_id: task_plan_id
    ).to_s
    run(:find_short_code, gid)
  end

end
