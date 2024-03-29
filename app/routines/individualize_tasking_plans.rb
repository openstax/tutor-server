class IndividualizeTaskingPlans
  # This routine should only be used when the task_plan is already locked
  lev_routine transaction: :read_committed, express_output: :tasking_plans

  protected

  def exec(task_plan:, role: nil, role_type: nil)
    outputs[:tasking_plans] = task_plan.tasking_plans.flat_map do |tasking_plan|
      target = tasking_plan.target

      # For example, a deleted period
      next [] if target.nil? || (target.respond_to?(:deleted?) && target.deleted?)

      roles = case target
      when Entity::Role
        target
      when User::Models::Profile
        Role::GetDefaultUserRole[target]
      when CourseProfile::Models::Course
        CourseMembership::GetCourseRoles.call(
          course: target, types: [:student, :teacher_student]
        ).outputs.roles
      when CourseMembership::Models::Period
        CourseMembership::GetPeriodStudentRoles.call(periods: target).outputs.roles +
        target.teacher_student_roles
      else
        raise NotYetImplemented
      end

      roles = [roles].flatten

      roles = roles.select { |rr| rr == role } unless role.nil?

      roles = roles.select { |role| role.role_type == role_type.to_s } unless role_type.nil?

      roles.map do |role|
        Tasks::Models::TaskingPlan.new(
          task_plan: task_plan,
          target: role,
          opens_at: tasking_plan.opens_at,
          due_at: tasking_plan.due_at,
          closes_at: tasking_plan.closes_at
        )
      end
    end.uniq(&:target)
  end
end
