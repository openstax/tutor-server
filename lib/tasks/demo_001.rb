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

    admin_profile = new_user_profile(username: 'admin', name: people.administrator)
    run(:make_administrator, user: admin_profile.entity_user)
    log("Added an admin user #{admin_profile.account.full_name}")

    ContentConfiguration[book.to_sym].each do | content |

      course = create_course(name: content.course_name)

      OpenStax::Cnx::V1.with_archive_url(url: archive_url) do
        cnx_book = run(:import_book, id: content.cnx_book).outputs.book
        log("Imported book #{content.course_name} #{content.cnx_book} from #{archive_url}.")
        run(:add_book, book: cnx_book, course: course)
      end


      teacher_profile = get_teacher(content.teacher) ||
                        new_user_profile(username: "teacher-#{content.teacher}",
                                         name: people.teachers[content.teacher])

      run(:add_teacher, course: course, user: teacher_profile.entity_user)

      log("Created course '#{content.course_name}' with '#{people.teachers[content.teacher]}' as teacher")
      content.periods.each do | period_content |

        period = run(:create_period, course: course, name: period_content.name).outputs.period
        log("  Created a period '#{period_content.name}'.")

        period_content.students.each do |initials|
          student = get_student(initials) ||
            new_user_profile(username: "user-#{initials}", name: people.students[initials])

          run(AddUserAsPeriodStudent, period: period, user: student.entity_user)

          log("    Added '#{people.students[initials]}'")
        end

      end # periods

    end # book

  end
end
