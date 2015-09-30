require_relative 'demo_base'
require_relative 'content_configuration'

## Imports a book from CNX and creates a course with periods from it's data
class DemoContent < DemoBase

  lev_routine

  disable_automatic_lev_transactions

  uses_routine FetchAndImportBookAndCreateEcosystem, as: :import_book
  uses_routine CreateCourse, as: :create_course
  uses_routine CreatePeriod, as: :create_period
  uses_routine AddEcosystemToCourse, as: :add_ecosystem
  uses_routine UserProfile::MakeAdministrator, as: :make_administrator
  uses_routine AddUserAsCourseTeacher, as: :add_teacher
  uses_routine AddUserAsPeriodStudent, as: :add_student
  uses_routine UserIsCourseStudent, as: :is_student
  uses_routine UserIsCourseTeacher, as: :is_teacher

  protected

  def exec(book: :all, print_logs: true, random_seed: nil, version: :defined)
    set_print_logs(print_logs)

    # By default, choose a fixed seed for repeatability and fewer surprises
    set_random_seed(random_seed)

    # Serial step
    courses = []
    ActiveRecord::Base.transaction do
      admin_profile = user_profile_for_username('admin') || \
                      new_user_profile(username: 'admin', name: people.admin)
      run(:make_administrator, user: admin_profile.user) unless admin_profile.is_admin?
      log("Admin user: #{admin_profile.account.full_name}")

      ContentConfiguration[book.to_sym].each do | content |
        course_name = content.course_name
        course = find_course(name: course_name) || create_course(name: course_name)
        courses << course
        log("Course: #{course_name}")

        teacher_profile = get_teacher_profile(content.teacher) ||
                          new_user_profile(username: people.teachers[content.teacher].username,
                                           name: people.teachers[content.teacher].name)
        teacher_user = teacher_profile.user
        log("Teacher: #{people.teachers[content.teacher].name}")

        run(:add_teacher, course: course, user: teacher_user) \
          unless run(:is_teacher, user: teacher_user, course: course).outputs.user_is_course_teacher

        content.periods.each_with_index do | period_content, index |
          period_name = period_content.name
          period = find_period(course: course, name: period_name) || \
                   run(:create_period, course: course, name: period_name).outputs.period
          log("  Period: #{period_content.name}")
          period_content.students.each do | initials |
            student_info = people.students[initials]
            profile = get_student_profile(initials) ||
                      new_user_profile(username: student_info.username, name:  student_info.name)
            user = profile.user
            log("    #{initials} #{student_info.username} (#{student_info.name})")
            run(:add_student, period: period, user: user) \
              unless run(:is_student, user: user, course: course).outputs.user_is_course_student
          end
        end
      end
    end

    # Parallel step
    # Disable multiple processes for now: Exercises (dev) times out with multiple requests...
    in_parallel(ContentConfiguration[book.to_sym], transaction: true,
                                                   max_processes: 0) do | contents, initial_index |

      index = initial_index

      contents.each do | content |

        book = content.cnx_book(version)
        course = courses[index]
        log("Starting book import for #{course.name} #{book} from #{
              OpenStax::Cnx::V1.archive_url_base}.")
        ecosystem = run(:import_book, book_cnx_id: book).outputs.ecosystem
        log("Book import complete")
        run(:add_ecosystem, ecosystem: ecosystem, course: course)

        index += 1

      end # book

    end # thread

    wait_for_parallel_completion

  end
end
