# Creates demo config yml.erb files from a course
class Demo::Export < Demo::Base
  lev_routine transaction: :read_committed, use_jobba: true

  protected

  # We skip anonymizing the research_identifier and student_identifier
  # because those fields are not exported
  def anonymize_accounts!(name, type, accounts)
    accounts.each_with_index do |account, index|
      user_name = "#{name} #{type.to_s.humanize} #{index + 1}"

      [ :first_name, :last_name, :full_name, :title, :username ].each do |field|
        account.public_send "#{field}=", "#{user_name} #{field.to_s.humanize}"
      end

      account.save!
    end
  end

  def relativize(time, original_reference, new_reference)
    return time.iso8601 if new_reference.nil?

    time_delta = (time - original_reference) + (new_reference - Time.current)

    "<%= Time.current #{time_delta >= 0 ? '+' : '-'} #{time_delta.abs/1.day}.days %>"
  end

  def write(basename, dirname, filename, representer, hash)
    dir = "config/demo/#{ActiveStorage::Filename.new(basename.to_s).sanitized
            }/#{ActiveStorage::Filename.new(dirname.to_s).sanitized}"
    FileUtils.mkdir_p dir

    File.write(
      "#{dir}/#{ActiveStorage::Filename.new(filename.to_s).sanitized}.yml.erb",
      representer.new(Demo::Mash.new(hash)).to_hash.to_yaml
    )
  end

  def exec(name:, courses:)
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
        period.update_attribute :name, "#{humanized_name} Period #{index + 1}"
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

      courses.flat_map(&:task_plans).each_with_index do |task_plan, index|
        task_plan.update_attribute :title, "#{humanized_name} Assignment #{index + 1}"
      end

      # Preload the rest of the data
      ActiveRecord::Associations::Preloader.new.preload(
        courses, offering: { ecosystem: :books },
                 task_plans: [
                   :tasking_plans, { tasks: { taskings: { role: { profile: :account } } } }
                 ]
      )

      teacher_profiles = teachers.map(&:role).map(&:profile)
      student_profiles = students.map(&:role).map(&:profile)

      courses.map(&:offering).uniq.each do |offering|
        write name, :import, offering.title, Api::V1::Demo::Import::Representer,
              book: offering.ecosystem.books.first, catalog_offering: offering
      end

      courses.each do |course|
        write name, :users, course.name, Api::V1::Demo::Users::Representer,
              teachers: teacher_profiles, students: student_profiles
        write name, :course, course.name, Api::V1::Demo::Course::Representer,
              catalog_offering: course.offering, course: course
        write name, :assign, course.name, Api::V1::Demo::Assign::Representer, course: course
        write name, :work, course.name, Api::V1::Demo::Work::Representer, course: course
      end

      raise ActiveRecord::Rollback
    end

    log_status
  end
end
