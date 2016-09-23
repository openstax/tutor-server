class FindDupes

  def self.call
    CSV.open('/tmp/student_work_info.csv','w+') do |csv|

      csv << ["AccountID", "CourseID", "PeriodID", "NumStepsComplete", "LatestWorkedAt", "Deleted?", "EnrollmentCreatedAt"]

      CourseMembership::Models::Enrollment
        .latest
        .with_deleted
        .includes{student.role.role_user.profile}
        .includes{student.role.taskings.task}.find_each do |ee|

        completed_steps_count = ee.student.role.taskings.inject(0){|sum, tasking| sum += tasking.task.completed_steps_count}
        latest_worked_at = ee.student.role.taskings.map{|tasking| tasking.task.last_worked_at}.compact.max

        csv << [ ee.student.role.role_user.profile.account_id,
                 ee.student.entity_course_id,
                 ee.course_membership_period_id,
                 completed_steps_count,
                 latest_worked_at,
                 ee.deleted? ? "Deleted" : "Active",
                 ee.created_at ]

      end
    end

    CSV.open('/tmp/teacher_accounts.csv','w+') do |csv|
      csv << ["AccountID", "CourseID", "TeacherID", "TeacherCreatedAt"]

      CourseMembership::Models::Teacher.includes{role.role_user.profile}.find_each do |teacher|
        csv << [ teacher.role.role_user.profile.account_id,
                 teacher.entity_course_id,
                 teacher.id,
                 teacher.created_at ]
      end

    end

  end

end
