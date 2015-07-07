require_relative 'demo_base'
require_relative 'demo/content_configuration'

class Demo001 < DemoBase

  lev_routine

  uses_routine FetchAndImportBook, as: :import_book
  uses_routine CreateCourse, as: :create_course
  uses_routine CreatePeriod, as: :create_period
  uses_routine AddBookToCourse, as: :add_book
  uses_routine UserProfile::MakeAdministrator, as: :make_administrator
  uses_routine AddUserAsCourseTeacher, as: :add_teacher

  protected

  def exec(book: :all, print_logs: true, random_seed: nil)

    set_print_logs(print_logs)

    # By default, choose a fixed seed for repeatability and fewer surprises
    set_random_seed(random_seed)

    archive_url = 'https://archive-staging-tutor.cnx.org/contents/'

    admin_profile = new_user_profile(username: 'admin', name: 'Administrator User')
    run(:make_administrator, user: admin_profile.entity_user)
    log("Added an admin user #{admin_profile.account.full_name}")

    teacher_profile = new_user_profile(username: 'teacher', name: 'Charles Morris')
    courses={}

    ContentConfiguration[book.to_sym].each do | content |
      cnx_book = nil
      OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
        cnx_book = run(:import_book, id: content.cnx_book_id).outputs.book
        log("Imported book #{content.course_name} #{content.cnx_book_id} from #{archive_url}.")
      end
      course = create_course(name: content.course_name)
      courses[content] = course
      run(:add_book, book: cnx_book, course: course)

      create_period(course: course)
      create_period(course: course)

      run(:add_teacher, course: course, user: teacher_profile.entity_user)
    end

    students = 10.times.collect do |ii|
      # if all books are being imported, switch between them
      # otherwise just use what we've got
      student_courses = if :all != book || 0 == ii % 5
                          courses.values
                        else
                          [courses.values.sample]
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
