class BuildTaskPlan
  lev_routine outputs: { task_plan: :_self },
              uses: GetCourseEcosystem

  protected

  def exec(course:, assistant: nil)
    run(:get_course_ecosystem, course: course).tap do |result|
      set(task_plan: Tasks::Models::TaskPlan.new(
        owner: course,
        assistant: assistant,
        content_ecosystem_id: result.ecosystem.try(:id)
      ))
    end
  end

end
