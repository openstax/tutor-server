# Adds the given role to the given period
# If the role is already a student in the same course, they will be moved between periods
class CourseMembership::AddStudent
  lev_routine

  protected

  def exec(period:, role:)
    course_periods = period.course.periods.to_a
    student = CourseMembership::Models::Student.find_by(period: course_periods, role: role)
    student ||= CourseMembership::Models::Student.new(role: role)
    student.period = period
    student.save
    transfer_errors_from(student, {type: :verbatim}, true)
  end
end
