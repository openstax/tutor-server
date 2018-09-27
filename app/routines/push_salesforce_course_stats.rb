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
  def exec(allow_error_email:)
    log { "Starting..." }

    applicable_courses.respond_to?(:find_in_batches) ?
      applicable_courses.find_in_batches(batch_size: COURSE_BATCH_SIZE, &method(:process_courses)) :
      applicable_courses.each_slice(COURSE_BATCH_SIZE, &method(:process_courses))

    notify_errors(allow_error_email)
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
    terms = CourseProfile::Models::Course.terms.values_at(:spring, :summer, :fall, :winter)

    CourseProfile::Models::Course
      .not_ended
      .where(is_test: false, is_preview: false, is_excluded_from_salesforce: false, term: terms)
      .preload(:offering, periods: { students: { role: { taskings: :task } } },
               teachers: { role: { role_user: { profile: :account } } })
  end

  def process_courses(courses)
    period_uuids = courses.flat_map(&:periods).sort_by(&:created_at).map(&:uuid)
    sf_tutor_course_periods_by_period_uuid = TCP.where(period_uuid: period_uuids)
                                                .to_a.index_by(&:period_uuid)

    courses.each do |course|
      catch(:go_to_next_record) { process_course(course, sf_tutor_course_periods_by_period_uuid) }
    end

    outputs.num_courses += courses.length
  end

  def process_course(course, sf_tutor_course_periods_by_period_uuid)
    begin
      num_teachers = course.teachers.length
      skip!(message: "No teachers", course: course) if num_teachers == 0

      num_periods = course.periods.length
      course_wide_stats = {
        base_year: base_year_for_course(course),
        book_name: course.offering.try!(:salesforce_book_name),
        contact_id: best_sf_contact_id_for_course(course),
        course_id: course.id,
        course_name: course.name,
        course_start_date: course.starts_at.to_date.iso8601,
        course_uuid: course.uuid,
        does_cost: course.does_cost,
        # The estimated enrollment is per course, but these records are per period
        # So we assign an equal part of the estimated enrollment to each period
        estimated_enrollment: course.estimated_student_count.try!(:/, num_periods),
        latest_adoption_decision: course.latest_adoption_decision,
        num_periods: num_periods,
        num_teachers: num_teachers,
        term: course.term.capitalize
      }

      course.periods.each do |period|
        catch(:go_to_next_record) do
          process_period(course, period, sf_tutor_course_periods_by_period_uuid, course_wide_stats)
        end
      end

      outputs.num_periods += num_periods
    rescue Exception => ee
      error!(exception: ee, course: course)
    end
  end

  def process_period(course, period, sf_tutor_course_periods_by_period_uuid, course_wide_stats)
    begin
      sf_tutor_course_period = sf_tutor_course_periods_by_period_uuid[period.uuid] ||
                               TCP.new(period_uuid: period.uuid)
      sf_tutor_course_period.error = nil

      begin
        sf_tutor_course_period.period_uuid = period.uuid
        sf_tutor_course_period.status = period.archived? ?
          OpenStax::Salesforce::Remote::TutorCoursePeriod::STATUS_ARCHIVED :
          OpenStax::Salesforce::Remote::TutorCoursePeriod::STATUS_APPROVED

        sf_tutor_course_period.reset_stats

        sf_tutor_course_period.created_at = period.created_at.iso8601

        course_wide_stats.each do |field, value|
          sf_tutor_course_period.public_send("#{field}=", value)
        end

        period.students.each do |student|
          sf_tutor_course_period.num_students += 1
          sf_tutor_course_period.num_students_comped += 1 if student.is_comped
          sf_tutor_course_period.num_students_dropped += 1 if student.dropped?
          sf_tutor_course_period.num_students_paid += 1 if student.is_paid
          sf_tutor_course_period.num_students_refunded += 1 \
            if student.first_paid_at.present? && !student.is_paid

          num_steps_completed = student.role.taskings.to_a.sum do |tasking|
            tasking.task.completed_steps_count
          end
          sf_tutor_course_period.num_students_with_work += 1 if num_steps_completed >= 10
        end

        skip!(message: "No changes", course: course, period: period) \
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
    when 'fall'
      course.year
    when 'spring', 'summer', 'winter'
      course.year - 1
    else
      raise "Unhandled course term #{course.term}"
    end
  end

  def best_sf_contact_id_for_course(course)
    course.teachers.sort_by(&:created_at)
          .map{ |tt| tt.role.role_user.profile.account.salesforce_contact_id }
          .compact.first.tap do |contact_id|
      error!(message: "No teachers have a SF contact ID", course: course) if contact_id.nil?
    end
  end

  def log(level = :info, *args, &block)
    Rails.logger.public_send(level, *args) { "[#{self.class.name}] #{block.call}" }
  end

  def error!(exception: nil, message: nil, course: nil, period: nil, non_fatal: false)
    begin
      outputs.num_errors += 1

      error = { message: message || exception.try(:message) }
      error[:exception] = {
        class: exception.class.name,
        message: exception.message,
        first_backtrace_line: exception.backtrace.try(:first)
      } if exception.present?
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

  def notify_errors(allow_error_email)
    return if @errors.empty?

    log(:warn) { "[#{self.class.name}] Errors: " + @errors.inspect }

    DevMailer.inspect_object(
      object: @errors,
      subject: "#{self.class.name} errors",
      to: Rails.application.secrets.salesforce['mail_recipients']
    ).deliver_later if allow_error_email && is_real_production?
  end

  def notify_skips
    log { "Skips: " + @skips.inspect } unless @skips.empty?
  end

  def is_real_production?
    Rails.application.secrets.environment_name == "prodtutor"
  end

end
