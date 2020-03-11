# Creates demo config yml.erb files from one or more courses
class Demo::Export < Demo::Base
  lev_routine transaction: :read_committed, use_jobba: true

  protected

  # We skip anonymizing the research_identifier and student_identifier
  # because those fields are not exported
  def anonymize_accounts!(name, type, accounts)
    accounts.each_with_index do |account, index|
      user_name = "#{name} #{type.to_s.humanize} #{index + 1}"

      # Disable sending updates to Accounts
      account.syncing = true

      account.username = user_name.downcase.gsub(/[^a-z\d]+/, '_')

      [ :first_name, :last_name, :full_name, :title ].each do |field|
        account.public_send "#{field}=", "#{user_name} #{field.to_s.humanize}"
      end

      account.save!
    end
  end

  def relativize(time, original_reference, new_reference)
    time = Time.parse(time) if time.is_a?(String)

    time_delta = (time - original_reference) + (new_reference - Time.current)

    "<%= Time.current #{time_delta >= 0 ? '+' : '-'} #{(time_delta.abs/1.day).round}.days %>"
  end

  def relativize_all!(object, original_reference, new_reference)
    case object
    when Hash
      object.each do |key, value|
        if key.to_s.ends_with? '_at'
          object[key] = relativize(value, original_reference, new_reference)
        else
          relativize_all! value, original_reference, new_reference
        end
      end
    when Array
      object.each { |value| relativize_all! value, original_reference, new_reference }
    else
      object
    end
  end

  def write(basename, dirname, filename, hash)
    dir = "config/demo/#{ActiveStorage::Filename.new(basename.to_s).sanitized
            }/#{ActiveStorage::Filename.new(dirname.to_s).sanitized}"
    FileUtils.mkdir_p dir
    File.write "#{dir}/#{ActiveStorage::Filename.new(filename.to_s).sanitized}", hash.to_yaml
  end

  def write_with_course(basename, dirname, course, new_starts_at, representer, hash)
    write basename, dirname, "#{course.name}.yml.erb", relativize_all!(
      representer.new(Demo::Mash.new(hash)).to_hash, course.starts_at, new_starts_at
    )
  end

  def exec(name:, courses:, starts_at: 2.months.ago)
    humanized_name = name.to_s.humanize

    # We anonymize data inside a transaction to make sure all records get the anonymized data,
    # then we rollback the transaction at the end
    CourseProfile::Models::Course.transaction(requires_new: true) do
      courses = [ courses ].flatten.map(&:reload)

      # Preload only the data that will be anonymized
      # Make sure each record is loaded only once here
      ActiveRecord::Associations::Preloader.new.preload(
        courses, [
          :task_plans,
          teachers: { role: { profile: :account } },
          periods: { students: { role: { profile: :account } } }
        ]
      )

      # Anonymize course and period names

      courses.each_with_index do |course, index|
        course.update_attribute :name, "#{humanized_name} Course #{index + 1}"
      end

      periods = courses.flat_map(&:periods)
      periods.each_with_index do |period, index|
        period.name = "#{humanized_name} Period #{index + 1}"
        period.enrollment_code = "#{humanized_name} Period #{index + 1} Enrollment Code"
        period.save validate: false
      end

      students = periods.flat_map(&:students)
      teachers = courses.flat_map(&:teachers)

      # Anonymize user data

      anonymize_accounts!(
        humanized_name, :student, students.map(&:role).map(&:profile).map(&:account)
      )
      anonymize_accounts!(
        humanized_name, :teacher, teachers.map(&:role).map(&:profile).map(&:account)
      )

      # Anonymize assignment titles

      courses.flat_map(&:task_plans).group_by(&:type).each do |type, task_plans|
        task_plans.each_with_index do |task_plan, index|
          assignment_title = "#{humanized_name} #{type.humanize} #{index + 1}"

          task_plan.update_attribute :title, assignment_title
          task_plan.update_attribute(
            :settings, task_plan.settings.merge(
              'external_url' => "https://example.com/#{assignment_title}"
            )
          ) if type == 'external'
        end
      end

      # Preload the rest of the data
      ActiveRecord::Associations::Preloader.new.preload(
        courses, offering: { ecosystem: :books },
                 task_plans: [
                   :tasking_plans, { tasks: { taskings: { role: { profile: :account } } } }
                 ]
      )

      courses.map(&:offering).compact.uniq.each do |offering|
        write name, :import, "#{offering.title}.yml", Api::V1::Demo::Import::Representer.new(
          Demo::Mash.new(book: offering.ecosystem.books.first, catalog_offering: offering)
        ).to_hash
      end

      courses.each do |course|
        course_teachers = teachers.select { |teacher| teacher.course == course }
        teacher_profiles = course_teachers.map(&:role).map(&:profile)

        course_students = students.select { |student| student.course == course }
        student_profiles = course_students.map(&:role).map(&:profile)

        write_with_course name, :users, course, starts_at, Api::V1::Demo::Users::Representer,
                                teachers: teacher_profiles, students: student_profiles
        write_with_course name, :course, course, starts_at, Api::V1::Demo::Course::Representer,
                                catalog_offering: course.offering, course: course
        write_with_course name, :assign, course, starts_at, Api::V1::Demo::Assign::Representer,
                                course: course
        write_with_course name, :work, course, starts_at, Api::V1::Demo::Work::Representer,
                                course: course
      end

      raise ActiveRecord::Rollback
    end

    log_status
  end
end
