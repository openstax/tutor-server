class BuildTaskPlan

  lev_routine express_output: :task_plan

  uses_routine GetCourseEcosystem, as: :get_ecosystem

  protected

  def exec(course:, assistant: nil)
    ecosystem = run(:get_ecosystem, course: course).outputs.ecosystem
    tp = Tasks::Models::TaskPlan.new(owner: course, assistant: assistant,
                                     content_ecosystem_id: ecosystem.try(:id))
    outputs[:task_plan] = tp
  end

end
