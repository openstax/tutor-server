class GetCourseUserTasks
  lev_routine outputs: { tasks: { name: Tasks::GetTasks, as: :get_tasks } },
              uses: { name: GetUserCourseRoles, as: :get_roles }

  protected

  def exec(course:, user:)
    roles = run(:get_roles, course: course, user: user).roles
    run(:get_tasks, roles: roles)
  end
end
