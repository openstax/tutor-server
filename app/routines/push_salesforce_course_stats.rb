class PushSalesforceCourseStats
  COURSE_BATCH_SIZE = 10

  lev_routine transaction: :no_transaction

  TCP = OpenStax::Salesforce::Remote::TutorCoursePeriod

  def initialize(*args)
    super
    outputs.num_courses = 0
    outputs.num_periods = 0
    outputs.num_updates = 0
    outputs.num_errors = 0
    outputs.num_skips = 0
    @errors = []
    @skips = []
  end

  # This code works hard to catch exceptions when pushing stats for periods, because
  # we don't want an issue with one course to kill stats for all remaining courses.
  # When an exception (or other issue) is encountered, we call `error!` which logs
  # the problem for logging and email notification, then stops the processing of
  # the current period via `throw`/`catch` calls (to avoid always remembering to
  # `return` after `error!` and to avoid using exceptions which we catch all of)
  def exec
    log { "Starting..." }

    applicable_courses.respond_to?(:find_in_batches) ?
      applicable_courses.find_in_batches(batch_size: COURSE_BATCH_SIZE, &method(:process_courses)) :
      applicable_courses.each_slice(COURSE_BATCH_SIZE, &method(:process_courses))

    notify_errors
    notify_skips

    log do
      "Processed #{outputs.num_courses} course(s) and #{outputs.num_periods} period(s); " +
      "wrote stats for #{outputs.num_updates} period(s); " +
      "skipped #{@skips.size} course(s) or period(s); " +
      "ran into #{@errors.size} error(s)."
    end
  end

  def applicable_courses
    # Don't update courses that have ended
    terms = CourseProfile::Models::Course.terms.values_at(
      :spring, :summer, :fall, :winter, :preview
    )

    courses = CourseProfile::Models::Course
      .not_ended
      .where(is_test: false, is_excluded_from_salesforce: false, term: terms)
      .where(
        <<~WHERE_SQL
          EXISTS (
            SELECT *
            FROM "course_membership_teachers"
            INNER JOIN "entity_roles"
              ON "entity_roles"."id" = "course_membership_teachers"."entity_role_id"
            INNER JOIN "user_profiles"
              ON "user_profiles"."id" = "entity_roles"."user_profile_id"
            INNER JOIN "openstax_accounts_accounts"
              ON "openstax_accounts_accounts"."id" = "user_profiles"."account_id"
            WHERE "openstax_accounts_accounts"."salesforce_contact_id" IS NOT NULL
              AND "course_membership_teachers"."course_profile_course_id" =
                "course_profile_courses"."id"
          )
        WHERE_SQL
      )

    courses = courses.where(is_preview: false).or(courses.where.not(preview_claimed_at: nil))

    courses.preload :offering, :periods, teachers: { role: { profile: :account } }
  end

  def process_courses(courses)
    periods = courses.flat_map(&:periods).sort_by(&:created_at)
    students_by_period_id = CourseMembership::Models::Student.select(
      :course_membership_period_id, :is_comped, :is_paid, :first_paid_at, :dropped_at, <<~SQL
        (
          SELECT COALESCE(SUM("tasks_tasks"."completed_steps_count"), 0)
          FROM "entity_roles"
            INNER JOIN "tasks_taskings" ON "tasks_taskings"."entity_role_id" = "entity_roles"."id"
            INNER JOIN "tasks_tasks" ON "tasks_tasks"."id" = "tasks_taskings"."tasks_task_id"
          WHERE "entity_roles"."id" = "course_membership_students"."entity_role_id"
        ) AS "num_steps_completed"
      SQL
    ).where(course_membership_period_id: periods.map(&:id)).group_by(&:course_membership_period_id)
    sf_tutor_course_periods_by_period_uuid = TCP.where(period_uuid: periods.map(&:uuid))
                                                .to_a.index_by(&:period_uuid)

    courses.each do |course|
      catch(:go_to_next_record) do
        process_course(course, students_by_period_id, sf_tutor_course_periods_by_period_uuid)
      end
    end

    outputs.num_courses += courses.length
  end

  def process_course(course, students_by_period_id, sf_tutor_course_periods_by_period_uuid)
    begin
      sf_teacher = best_sf_teacher(course)
      num_periods = course.periods.reject(&:archived?).length

      course_wide_stats = {
        base_year: base_year_for_course(course),
        book_name: course.offering&.salesforce_book_name,
        contact_id: sf_teacher.role.profile.account.salesforce_contact_id,
        course_id: course.id,
        course_name: course.name,
        course_start_date: course.starts_at.to_date.iso8601,
        course_uuid: course.uuid,
        does_cost: course.does_cost,
        # The estimated enrollment is per course, but these records are per period
        # So we assign an equal part of the estimated enrollment to each period
        latest_adoption_decision: course.latest_adoption_decision,
        num_periods: num_periods,
        num_teachers: course.teachers.reject(&:deleted?).length,
        term: course.term.capitalize
      }

      course.periods.each do |period|
        catch(:go_to_next_record) do
          students = students_by_period_id[period.id] || []
          sf_tutor_course_period = sf_tutor_course_periods_by_period_uuid[period.uuid] ||
                                   TCP.new(period_uuid: period.uuid)

          process_period(
            course, sf_teacher, period, students, sf_tutor_course_period, course_wide_stats
          )
        end
      end

      outputs.num_periods += num_periods
    rescue Exception => ee
      error!(exception: ee, course: course)
    end
  end

  def process_period(
    course, sf_teacher, period, students, sf_tutor_course_period, course_wide_stats
  )
    begin
      sf_tutor_course_period.error = nil

      begin
        sf_tutor_course_period.period_uuid = period.uuid
        sf_tutor_course_period.status = if course.is_preview?
          OpenStax::Salesforce::Remote::TutorCoursePeriod::STATUS_PREVIEW
        elsif period.archived?
          OpenStax::Salesforce::Remote::TutorCoursePeriod::STATUS_ARCHIVED
        elsif sf_teacher.deleted?
          OpenStax::Salesforce::Remote::TutorCoursePeriod::STATUS_DROPPED
        else
          OpenStax::Salesforce::Remote::TutorCoursePeriod::STATUS_APPROVED
        end

        sf_tutor_course_period.reset_stats

        created_at = [ course.preview_claimed_at, period.created_at ].compact.max.iso8601
        sf_tutor_course_period.created_at = created_at

        course_wide_stats.each do |field, value|
          sf_tutor_course_period.public_send("#{field}=", value)
        end

        # Estimate student enrollment in the course section:
        # 0 if the section is archived
        # null if the course doesn't have an estimate
        # Otherwise, the course-wide estimate divided by the number of non-archived sections
        sf_tutor_course_period.estimated_enrollment = if period.archived?
          0
        elsif course.estimated_student_count.nil?
          nil
        else
          course.estimated_student_count/sf_tutor_course_period.num_periods
        end

        students.each do |student|
          sf_tutor_course_period.num_students += 1
          sf_tutor_course_period.num_students_comped += 1 if student.is_comped
          sf_tutor_course_period.num_students_dropped += 1 if student.dropped?
          sf_tutor_course_period.num_students_paid += 1 if student.is_paid
          sf_tutor_course_period.num_students_refunded += 1 \
            if student.first_paid_at.present? && !student.is_paid

          sf_tutor_course_period.num_students_with_work += 1 if student.num_steps_completed >= 10
        end

        skip!(message: 'No changes', course: course, period: period) \
          if !sf_tutor_course_period.changed?
      rescue Exception => ee
        # Add the error to the TCP and `error!`
        # but non fatally so the error can get saved to the TCP
        sf_tutor_course_period.error = "Unable to update stats: #{ee.message}"
        error!(message: sf_tutor_course_period.error, exception: ee,
               course: course, period: period, non_fatal: true)
      end

      if sf_tutor_course_period.save
        outputs.num_updates += 1
      else
        error!(message: sf_tutor_course_period.errors.full_messages.join(', '),
               course: course, period: period)
      end
    rescue Exception => ee
      error!(exception: ee, course: course, period: period)
    end
  end

  def base_year_for_course(course)
    case course.term
    when 'fall', 'preview'
      course.year
    when 'spring', 'summer', 'winter'
      course.year - 1
    else
      raise "Unhandled course term #{course.term}"
    end
  end

  def best_sf_teacher(course)
    sf_teachers = course.teachers.reject do |teacher|
      teacher.role.profile.account.salesforce_contact_id.nil?
    end

    # First non-deleted teacher to join or last teacher to be deleted
    sf_teachers.reject(&:deleted?).sort_by(&:created_at).first ||
    sf_teachers.sort_by(&:deleted_at).last
  end

  def log(level = :info, *args, &block)
    Rails.logger.public_send(level, *args) { "[#{self.class.name}] #{block.call}" }
  end

  def error!(exception: nil, message: nil, course: nil, period: nil, non_fatal: false)
    begin
      outputs.num_errors += 1

      error = { message: message || exception&.message || 'No message or exception given' }
      error[:exception] = exception
      error[:course] = course.id if course.present?
      error[:period] = period.id if period.present?

      @errors << error
    ensure
      throw :go_to_next_record unless non_fatal
    end
  end

  def skip!(message: nil, course: nil, period: nil)
    begin
      outputs.num_skips += 1

      skip = {}
      skip[:message] = message if message.present?
      skip[:course] = course.id if course.present?
      skip[:period] = period.id if period.present?

      @skips << skip if skip.present?
    ensure
      throw :go_to_next_record
    end
  end

  def notify_errors
    return if @errors.empty?

    log_errors = @errors.map do |error|
      exception = error[:exception]
      next error unless exception.present?

      error.merge(
        exception: {
          class: exception.class.name,
          message: exception.message,
          first_backtrace_line: exception.backtrace&.first
        }
      )
    end
    log(:error) { "[#{self.class.name}] Errors: " + log_errors.inspect }

    @errors.each do |error|
      exception = error[:exception]

      if exception.nil?
        Raven.capture_message error[:message], extra: error.except(:message)
      else
        Raven.capture_exception exception, extra: error.except(:exception)
      end
    end
  end

  def notify_skips
    log { "Skips: " + @skips.inspect } unless @skips.empty?
  end
end
