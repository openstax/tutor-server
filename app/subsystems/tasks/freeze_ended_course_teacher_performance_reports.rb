class Tasks::FreezeEndedCourseTeacherPerformanceReports
  BATCH_SIZE = 1000

  lev_routine transaction: :no_transaction

  def exec(current_time: Time.current)
    loop do
      courses = CourseProfile::Models::Course.transaction do
        courses = CourseProfile::Models::Course
          .lock
          .where(CourseProfile::Models::Course.arel_table[:ends_at].lteq current_time)
          .where(teacher_performance_report: nil)
          .order(ends_at: :desc)
          .preload(teachers: :role)
          .first(BATCH_SIZE)

        courses.each do |course|
          performance_report = Tasks::GetPerformanceReport[
            course: course,
            is_teacher: true,
            is_frozen: false
          ]

          course.teacher_performance_report = Api::V1::PerformanceReport::Representer.new(
            performance_report
          ).to_hash

          course.teachers.each do |teacher|
            Tasks::ExportPerformanceReport.call(
              course: course,
              role: teacher.role,
              performance_report: performance_report
            )
          end
        end

        CourseProfile::Models::Course.import courses, validate: false, on_duplicate_key_update: {
          conflict_target: [ :id ], columns: [ :teacher_performance_report ]
        }

        courses
      end

      break if courses.size < BATCH_SIZE
    end
  end
end
