class GetCourseUserTasks
  lev_routine express_output: :tasks

  uses_routine GetUserCourseRoles,
               as: :get_roles,
               translations: { outputs: { type: :verbatim } }
  uses_routine Tasks::GetTasks,
               as: :get_tasks,
               translations: { outputs: { type: :verbatim } }

  protected

  def exec(course:, user:)
    run(:get_roles, course: course, user: user)
    run(:get_tasks, roles: outputs[:roles])
  end
end
