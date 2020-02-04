class DeleteTeacherStudentsForDeletedTeachers < ActiveRecord::Migration[5.2]
  def up
    CourseMembership::Models::Teacher.where.not(deleted_at: nil).preload(
      role: { profile: { roles: :teacher_student } }
    ).find_each do |teacher|
      teacher.role.profile.roles.map(&:teacher_student).compact.select do |teacher_student|
        teacher_student.course_profile_course_id == teacher.course_profile_course_id
      end.reject(&:deleted?).each(&:destroy!)
    end
  end

  def down
  end
end
