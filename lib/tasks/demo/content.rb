require_relative 'demo_base'
require_relative 'content_configuration'

## Imports a book from CNX and creates a course with periods from it's data
class DemoContent < DemoBase

  lev_routine

  uses_routine FetchAndImportBook, as: :import_book
  uses_routine CreateCourse, as: :create_course
  uses_routine CreatePeriod, as: :create_period
  uses_routine AddEcosystemToCourse, as: :add_ecosystem
  uses_routine UserProfile::MakeAdministrator, as: :make_administrator
  uses_routine AddUserAsCourseTeacher, as: :add_teacher

  protected

  def exec(book: :all, print_logs: true, random_seed: nil, version: :defined)

    set_print_logs(print_logs)

    # By default, choose a fixed seed for repeatability and fewer surprises
    set_random_seed(random_seed)

    admin_profile = new_user_profile(username: 'admin', name: people.admin)
    run(:make_administrator, user: admin_profile.entity_user)
    log("Added an admin user #{admin_profile.account.full_name}")

    ContentConfiguration[book.to_sym].each do | content |

      course = create_course(name: content.course_name)

      content.periods.each_with_index do | period_content, index |
        period = run(:create_period, course: course, name: period_content.name).outputs.period
        log("  Created period: #{period_content.name}")
        period_content.students.each do | initials |
          student_info = people.students[initials]
          profile = get_student_profile(initials) ||
                    new_user_profile(username: student_info.username, name:  student_info.name)
          log("    #{initials} (#{student_info.name})")

          run(AddUserAsPeriodStudent, period: period, user: profile.entity_user)
        end
      end

      book = content.cnx_book(version)
      log("Starting book import for #{course.name} #{book} from #{
            OpenStax::Cnx::V1.archive_url_base}.")
      ecosystem = run(:import_book, id: book).outputs.ecosystem
      log("Imported book complete.")
      run(:add_ecosystem, ecosystem: ecosystem, course: course)

      teacher_profile = get_teacher_profile(content.teacher) ||
                        new_user_profile(username: people.teachers[content.teacher].username,
                                         name: people.teachers[content.teacher].name)

      run(:add_teacher, course: course, user: teacher_profile.entity_user)

      log("'#{people.teachers[content.teacher].name}' is course teacher")

    end # book

  end
end
