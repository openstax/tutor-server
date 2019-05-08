STUDENT_DUPES_EXPORT_PATH = 'tmp/exports/student_work_info.csv'
TEACHER_DUPES_EXPORT_PATH = 'tmp/exports/teacher_accounts.csv'

desc "Find users enrolled multiple times in the same course"
task find_dupes: :environment do
  CSV.open(STUDENT_DUPES_EXPORT_PATH,'w+') do |csv|

    csv << ["AccountID", "CourseID", "PeriodID", "NumStepsComplete", "LatestWorkedAt", "Dropped?", "EnrollmentCreatedAt"]

    CourseMembership::Models::Enrollment
      .latest
      .includes{student.role.profile}
      .includes{student.role.taskings.task}.find_each do |ee|

      completed_steps_count = ee.student.role.taskings.inject(0) do |sum, tasking|
        sum += tasking.task.completed_steps_count
      end
      latest_worked_at = ee.student.role.taskings.map do |tasking|
        tasking.task.last_worked_at
      end.compact.max

      csv << [ ee.student.role.profile.account_id,
               ee.student.course_profile_course_id,
               ee.course_membership_period_id,
               completed_steps_count,
               latest_worked_at,
               ee.student.dropped? ? "Dropped" : "Active",
               ee.created_at ]

    end
  end

  puts "Wrote student data to #{STUDENT_DUPES_EXPORT_PATH}"

  CSV.open(TEACHER_DUPES_EXPORT_PATH,'w+') do |csv|
    csv << ["AccountID", "CourseID", "TeacherID", "TeacherCreatedAt"]

    CourseMembership::Models::Teacher.includes{role.profile}.find_each do |teacher|
      csv << [ teacher.role.profile.account_id,
               teacher.course_profile_course_id,
               teacher.id,
               teacher.created_at ]
    end

  end

  puts "Wrote teacher data to #{TEACHER_DUPES_EXPORT_PATH}"
end
