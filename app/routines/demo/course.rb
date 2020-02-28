# Creates a demo course or sets the course's name, catalog offering and ecosystem
# Sets the course's periods and enrolls demo teachers and demo students into them
class Demo::Course < Demo::Base
  lev_routine transaction: :read_committed, use_jobba: true

  uses_routine CreateCourse, as: :create_course
  uses_routine CreatePeriod, as: :create_period
  uses_routine CourseMembership::UpdatePeriod, as: :update_period
  uses_routine AddEcosystemToCourse, as: :add_ecosystem
  uses_routine AddUserAsCourseTeacher, as: :add_teacher
  uses_routine AddUserAsPeriodStudent, as: :add_student
  uses_routine MoveStudent, as: :move_student
  uses_routine UserIsCourseStudent, as: :is_student
  uses_routine UserIsCourseTeacher, as: :is_teacher

  protected

  # This exception exists to let background jobs retry instead of
  # failing instantly with ActiveRecord::RecordNotFound
  class Demo::CatalogOfferingNotFound < StandardError
  end

  # Either course id or (course name and (catalog_offering id or catalog_offering title))
  # must be provided
  def exec(course:)
    catalog_offering = course[:catalog_offering]
    unless catalog_offering.blank?
      begin
        offering_model = if catalog_offering[:id].present?
          Catalog::Models::Offering.find catalog_offering[:id]
        elsif catalog_offering[:title].present?
          Catalog::Models::Offering.order(created_at: :desc).find_by!(
            title: catalog_offering[:title]
          )
        end
      rescue ActiveRecord::RecordNotFound
        raise Demo::CatalogOfferingNotFound
      end
    end

    course_hash = course[:course]
    course_model = find_course_by_id course_hash[:id]

    attrs = course_hash.slice(:term, :year, :is_college, :is_test).merge(
      is_preview: false, is_concept_coach: false
    )
    attrs = attrs.merge(name: course_hash[:name]) unless course_hash[:name].blank?
    attrs[:starts_at] = DateTime.parse(course_hash[:starts_at]) rescue nil \
      unless course_hash[:starts_at].blank?
    attrs[:ends_at] = DateTime.parse(course_hash[:ends_at]) rescue nil \
      unless course_hash[:ends_at].blank?

    if course_model.nil?
      raise(
        ArgumentError, 'You must provide a catalog offering when creating a new course'
      ) if offering_model.nil?

      attrs[:catalog_offering] = offering_model

      attrs[:term] ||= :demo
      attrs[:year] ||= Time.zone.now.year
      attrs[:is_college] = true if attrs[:is_college].nil?
      attrs[:is_test] = true if attrs[:is_test].nil?

      course_model = run(:create_course, attrs).outputs.course

      log { "Course Created: #{course_model.name} (id: #{course_model.id})" }
    else
      attrs[:name] = course[:course][:name]
      attrs[:offering] = offering_model unless offering_model.nil?

      course_model.update_attributes attrs

      run(:add_ecosystem, course: course_model, ecosystem: offering_model.ecosystem) \
        unless offering_model.nil?

      log { "Course Found: #{course_model.name} (id: #{course_model.id})" }
    end

    usernames = (
      course_hash[:teachers].map { |teacher| teacher[:username] } +
      course_hash[:periods].flat_map do |period|
        period[:students].map { |student| student[:username] }
      end
    ).uniq
    users_by_username = User::Models::Profile.joins(:account)
                          .where(account: { username: usernames })
                          .preload(:account)
                          .index_by(&:username)
    missing_usernames = usernames - users_by_username.keys
    raise(
      ActiveRecord::RecordNotFound,
      "Could not find users for the following username(s): #{missing_usernames.join(', ')}"
    ) unless missing_usernames.empty?

    course_hash[:teachers].each do |teacher|
      user = users_by_username[teacher[:username]]

      run(:add_teacher, course: course_model, user: user) \
        unless run(:is_teacher, user: user, course: course_model).outputs.is_course_teacher

      log { "Teacher: #{user.username} (#{user.name})" }
    end

    course_hash[:periods].each_with_index do |period, index|
      period_model = CourseMembership::Models::Period.find_by(
        course: course_model, name: period[:name]
      ) || run(:create_period, course: course_model, name: period[:name]).outputs.period

      run(:update_period, period: period_model, enrollment_code: period[:enrollment_code]) \
        unless period[:enrollment_code].blank?

      log { "  Period: #{period_model.name}" }

      period[:students].each do |student|
        user = users_by_username[student[:username]]

        log { "    Student: #{user.username} (#{user.name})" }

        out = run(
          :is_student, user: user, course: course_model, include_dropped_students: true
        ).outputs
        if out.is_course_student
          next if out.student.period == period_model

          run(:move_student, period: period, student: out.student)
        else
          run(
            :add_student,
            period: period_model,
            user: user,
            student_identifier: SecureRandom.urlsafe_base64(10)
          )
        end
      end
    end

    outputs.course = course_model

    log_status outputs.course.name
  end
end
