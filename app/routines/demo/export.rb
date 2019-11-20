# Creates demo config yml.erb files from a course
class Demo::Export < Demo::Base
  lev_routine transaction: :read_committed, use_jobba: true

  protected

  def write(basename, dirname, filename, representer, hash)
    dir = "config/demo/#{ActiveStorage::Filename.new(basename.to_s).sanitized
            }/#{ActiveStorage::Filename.new(dirname.to_s).sanitized}"
    FileUtils.mkdir_p dir

    File.write(
      "#{dir}/#{ActiveStorage::Filename.new(filename.to_s).sanitized}.yml.erb",
      representer.new(Demo::Mash.new(hash)).to_hash.to_yaml
    )
  end

  def relativize(time, original_reference, new_reference)
    return time.iso8601 if new_reference.nil?

    time_delta = (time - original_reference) + (new_reference - Time.current)

    "<%= Time.current #{time_delta >= 0 ? '+' : '-'} #{time_delta.abs/1.day}.days %>"
  end

  def exec(name:, courses:)
    ActiveRecord::Associations::Preloader.new.preload(
      courses, teachers: { role: :profile },
               students: { role: :profile },
               offering: { ecosystem: :books },
               task_plans: [ :tasking_plans, { tasks: :taskings } ]

    )
    teachers = courses.flat_map(&:teachers).map(&:role).map(&:profile)
    students = courses.flat_map(&:students).map(&:role).map(&:profile)
    catalog_offerings = courses.map(&:offering).uniq

    catalog_offerings.each do |offering|
      write name, :import, offering.title, Api::V1::Demo::Import::Representer,
            book: offering.ecosystem.books.first, catalog_offering: offering
    end

    courses.each do |course|
      write name, :users, course.name, Api::V1::Demo::Users::Representer, teachers: teachers,
                                                                          students: students
      write name, :course, course.name, Api::V1::Demo::Course::Representer,
            catalog_offering: course.offering, course: course
      write name, :assign, course.name, Api::V1::Demo::Assign::Representer, course: course
      write name, :work, course.name, Api::V1::Demo::Work::Representer, course: course
    end

    log_status
  end
end
