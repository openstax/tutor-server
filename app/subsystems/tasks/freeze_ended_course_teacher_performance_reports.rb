class Tasks::FreezeEndedCourseTeacherPerformanceReports
  BATCH_SIZE = 1000

  lev_routine transaction: :no_transaction

  def exec(current_time: Time.current)
    loop do
      courses = CourseProfile::Models::Course.transaction do
        courses = CourseProfile::Models::Course.lock.where(
          CourseProfile::Models::Course.arel_table[:ends_at].lteq current_time
        ).where(teacher_performance_report: nil).order(ends_at: :desc).first(BATCH_SIZE)

        courses.each do |course|
          course.teacher_performance_report = Api::V1::PerformanceReport::Representer.new(
            Tasks::GetPerformanceReport[course: course, is_teacher: true]
          ).to_hash
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
