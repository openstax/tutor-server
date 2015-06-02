require_relative 'demo_base'

class Demo001 < DemoBase

  lev_routine

  uses_routine FetchAndImportBook, as: :import_book, translations: { outputs: { type: :verbatim } }
  uses_routine CreateCourse, as: :create_course
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
    cnx_book_id = "93e2b09d-261c-4007-a987-0b3062fe154b#{version_string}"

    OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
      run(:import_book, id: cnx_book_id)
      log("Imported book #{cnx_book_id} from #{archive_url}.")
    end

    course = create_course(name: 'Physics I')
    run(:add_book, book: outputs.book, course: course)

    admin_profile = new_user_profile(username: 'admin', name: 'Administrator User')
    run(:make_administrator, user: admin_profile.entity_user)
    log("Added an admin user #{admin_profile.account.full_name}")

    teacher_profile = new_user_profile(username: 'teacher', name: 'Charles Morris')
    run(:add_teacher, course: course, user: teacher_profile.entity_user)

    students = 20.times.collect do |ii|
      new_course_student(course: course, username: "student#{(ii + 1).to_s.rjust(2,'0')}")
    end

    log("Added #{teacher_profile.account.full_name} as a teacher and added #{students.count} students.")
  end

end
