class GetStudentRoster
  lev_routine express_output: :students

  protected

  def exec(course:)
    students = CourseMembership::Models::Student
      .joins { period }
      .where { period.entity_course_id == course.id }

    role_ids = students.collect(&:entity_role_id)
    @role_users = Role::Models::User.where { entity_role_id.in role_ids }
    user_ids = @role_users.collect(&:entity_user_id)

    @profiles = UserProfile::Models::Profile
      .where { entity_user_id.in user_ids }
      .includes { account }
      .references(:first_name, :last_name, :full_name)

    outputs[:students] = students.collect do |student|
      profile = get_profile_by_role_id(student.entity_role_id)
      Hashie::Mash.new({
        id: student.id,
        first_name: profile.first_name,
        last_name: profile.last_name,
        name: profile.full_name,
        period_id: student.course_membership_period_id,
        role_id: student.entity_role_id
      })
    end
  end

  def get_profile_by_role_id(role_id)
    user_id = @role_users.select { |ru| ru.entity_role_id == role_id }.first.entity_user_id
    @profiles.select { |p| p.entity_user_id == user_id }.first
  end
end
