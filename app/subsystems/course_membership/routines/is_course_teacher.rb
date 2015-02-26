class CourseMembership::IsCourseTeacher
  lev_routine

  protected

  def exec(course:, role: :missing, roles: :missing)
    unless role_param_combo_is_valid(role, roles)
      fatal_error(
        code: :invalid_usage,
        offending_inputs: [role, roles],
        message: "exactly one of 'role' or 'roles' must be specified")
    end

    roles = [role] unless role == :missing
    role_ids = roles.collect{|r| r.id}

    outputs[:is_course_teacher] = CourseMembership::Teacher.where{entity_course_id == course.id} \
                                                           .where{entity_role_id >> role_ids}.any?
  end

  def role_param_combo_is_valid(role, roles)
    [role, roles].select{|x| x == :missing}.count == 1
  end
end
