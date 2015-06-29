require_relative 'demo_base'

class Demo001 < DemoBase

  lev_routine

  uses_routine FetchAndImportBook, as: :import_book
  uses_routine CreateCourse, as: :create_course
  uses_routine CreatePeriod, as: :create_period
  uses_routine AddBookToCourse, as: :add_book
  uses_routine UserProfile::MakeAdministrator, as: :make_administrator
  uses_routine AddUserAsCourseTeacher, as: :add_teacher

  protected

  STABLE_VERSION = 1.18

  def exec(print_logs: true, book_version: :latest, random_seed: nil)

    set_print_logs(print_logs)

    # By default, choose a fixed seed for repeatability and fewer surprises
    set_random_seed(random_seed)

    version_string = case book_version.to_sym
                     when :latest
                       ''
                     when :stable
                       "@#{STABLE_VERSION}"
                     else
                       book_version.blank? ? '' : "@#{book_version.to_s}"
                     end

    archive_url = 'https://archive-staging-tutor.cnx.org/contents/'

    cnx_books = {
      'Biology I' => "ccbc51fa-49f3-40bb-98d6-07a15a7ab6b7#{version_string}",
      'Physics I' => "93e2b09d-261c-4007-a987-0b3062fe154b#{version_string}"
    }

    admin_profile = new_user_profile(username: 'admin', name: 'Administrator User')
    run(:make_administrator, user: admin_profile.entity_user)
    log("Added an admin user #{admin_profile.account.full_name}")

    teacher_profile = new_user_profile(username: 'teacher', name: 'Charles Morris')
    courses={}
    cnx_books.each do | course_name, cnx_book_id |
      book = nil
      OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
        book = run(:import_book, id: cnx_book_id).outputs.book
        log("Imported book #{course_name} #{cnx_book_id} from #{archive_url}.")
      end
      course_code = course_name[0...3].downcase
      course = create_course(name: course_name)
      courses[course_code] = course
      run(:add_book, book: book, course: course)

      create_period(course: course)
      create_period(course: course)

      run(:add_teacher, course: course, user: teacher_profile.entity_user)

    end

    students = 10.times.collect do |ii|
      # Hey Fizzbuzz :)
      student_courses = if 0 == ii % 5
                          courses.values
                        elsif 0 == ii % 2
                          [courses['bio']]
                        else
                          [courses['phy']]
                        end
      username = "student#{(ii + 1).to_s.rjust(2,'0')}"
      user = new_user_profile(username: username).entity_user

      student_courses.map do | course |
        run(AddUserAsPeriodStudent, period: course.periods[ii%2], user: user)
      end

    end

    log("Added #{teacher_profile.account.full_name} as a teacher and added #{students.flatten.count} students.")

  end
end
