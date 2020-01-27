class IndividualizeTaskingPlans

  lev_routine express_output: :tasking_plans

  protected

  def exec(task_plan:, role_type: nil)
    tasking_plans = task_plan.tasking_plans
    tasking_plans = tasking_plans.preload(:time_zone) if task_plan.persisted?
    outputs[:tasking_plans] = tasking_plans.flat_map do |tasking_plan|
      target = tasking_plan.target

      # For example, a deleted period
      next [] if target.nil? || (target.respond_to?(:deleted?) && target.deleted?)

      roles = case target
      when Entity::Role
        target
      when User::Models::Profile
        strategy = ::User::Strategies::Direct::User.new(target)
        user = ::User::User.new(strategy: strategy)
        Role::GetDefaultUserRole[user]
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

      roles = roles.select { |role| role.role_type == role_type.to_s } unless role_type.nil?

      roles.map do |role|
        Tasks::Models::TaskingPlan.new(
          task_plan: task_plan,
          target: role,
          opens_at: tasking_plan.opens_at,
          due_at: tasking_plan.due_at,
          closes_at: tasking_plan.closes_at,
          time_zone: tasking_plan.time_zone
        )
      end
    end.uniq(&:target)
  end

end
