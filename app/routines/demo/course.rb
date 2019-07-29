# Creates a demo course or sets the course's name, catalog offering and ecosystem
# Sets the course's periods and enrolls demo teachers and demo students into them
class Demo::Course < Demo::Base
  lev_routine use_jobba: true

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

  # Either course_id or (course_name and (catalog_offering_id or catalog_offering_title))
  # must be provided
  def exec(course:)
    catalog_offering = course[:catalog_offering]
    unless catalog_offering.blank?
      offering_model = if catalog_offering[:id].present?
        Catalog::Models::Offering.find catalog_offering[:id]
      elsif catalog_offering[:title].present?
        Catalog::Models::Offering.order(created_at: :desc).find_by! title: catalog_offering[:title]
      end
    end
    model = CourseProfile::Models::Course.find(course[:course][:id]) \
      if course[:course][:id].present?

    attrs = course.slice(:term, :year, :is_college).merge(
      catalog_offering: offering_model,
      is_preview: false,
      is_concept_coach: false,
      is_test: true
    )
    attrs = attrs.merge(name: course[:course][:name]) unless course[:course][:name].blank?
    attrs[:starts_at] = DateTime.parse(course[:starts_at]) rescue nil \
      unless course[:starts_at].blank?
    attrs[:ends_at] = DateTime.parse(course[:ends_at]) rescue nil unless course[:ends_at].blank?

    if model.nil?
      raise(
        ArgumentError, 'You must provide a catalog offering when creating a new course'
      ) if offering_model.nil?

      attrs[:term] ||= :demo
      attrs[:year] ||= Time.current.year
      attrs[:is_college] = true if attrs[:is_college].blank?

      model = run(:create_course, attrs).outputs.course

      log { "Course Created: #{model.name} (id: #{model.id})" }
    else
      model.update_attributes(attrs)

      log { "Course Found: #{model.name} (id: #{model.id})" }
    end

    usernames = (
      course[:teachers].map { |teacher| teacher[:username] } +
      course[:periods].flat_map { |period| period[:students].map { |student| student[:username] } }
    ).uniq
    users_by_username = User::Models::Profile.joins(:account)
                          .where(account: { username: usernames })
                          .preload(:account)
                          .index_by(&:username)
    missing_usernames = usernames - users_by_username.keys
    raise(
      "Could not find users for the following username(s): #{missing_usernames.join(', ')}"
    ) unless missing_usernames.empty?

    course[:teachers].each do |teacher|
      user = users_by_username[teacher[:username]]

      run(:add_teacher, course: model, user: user) \
        unless run(:is_teacher, user: user, course: model).outputs.is_course_teacher

      log { "Teacher: #{user.username} (#{user.name})" }
    end

    course[:periods].each_with_index do |period, index|
      period_model = CourseMembership::Models::Period.find_by(course: model, name: period[:name]) ||
                     run(:create_period, course: model, name: period[:name]).outputs.period.to_model

      run(:update_period, period: period_model, enrollment_code: period[:enrollment_code]) \
        unless period[:enrollment_code].blank?

      log { "  Period: #{period_model.name}" }

      period[:students].each do |student|
        user = users_by_username[student[:username]]

        log { "    Student: #{user.username} (#{user.name})" }

        out = run(:is_student, user: user, course: model, include_dropped_students: true).outputs
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

    outputs.course = model

    log_status outputs.course.name
  end
end
