class Tasks::FreezeEndedCourseTeacherPerformanceReports
  BATCH_SIZE = 1000

  lev_routine transaction: :no_transaction

  def exec(current_time: Time.current)
    co = CourseProfile::Models::Course.arel_table
    ca = CourseProfile::Models::Cache.arel_table
    loop do
      courses = CourseProfile::Models::Course.transaction do
        courses = CourseProfile::Models::Course
          .lock
          .where(CourseProfile::Models::Course.arel_table[:ends_at].lteq current_time)
          .where.not(
            CourseProfile::Models::Cache.where(ca[:course_profile_course_id].eq co[:id]).arel.exists
          )
          .order(ends_at: :desc)
          .preload(teachers: :role)
          .first(BATCH_SIZE)

        caches = courses.map do |course|
          performance_report = Tasks::GetPerformanceReport[
            course: course,
            is_teacher: true,
            is_frozen: false
          ]

          # The export routines tend to modify the performance report to remove stuff,
          # so we create the representation now before that can happen
          performance_report_hash = Api::V1::PerformanceReport::Representer.new(
            performance_report
          ).to_hash

          course.teachers.each do |teacher|
            Tasks::ExportPerformanceReport.call(
              course: course,
              role: teacher.role,
              performance_report: performance_report
            )
          end

          CourseProfile::Models::Cache.new(
            course: course, teacher_performance_report: performance_report_hash
          )
        end

        CourseProfile::Models::Cache.import caches, validate: false

        courses
      end

      break if courses.size < BATCH_SIZE
    end
  end
end
