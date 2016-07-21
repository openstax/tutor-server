require_relative 'base'

# Loops through the courses and periods that are to be created and worked.
# Logs the student's assignments for review
class Demo::Show < Demo::Base

  lev_routine

  protected

  def exec(config: :all, print_logs: true)
    set_print_logs(print_logs)

    students = {}
    Demo::ContentConfiguration[config].each do | content |

      content.periods.each do | period |
        (period.students || []).each do | initials |
          person = people.students[initials]

          unless student = students[person.username]
            student = students[person.username] = OpenStruct.new(
              courses: {}, initials: initials, username: person.username, name: person.name
            )
          end

          unless course = student.courses[content.course_name]
            course = student.courses[content.course_name] = OpenStruct.new(assignments: [])
          end

          content.assignments.each do | assignment |
            assignment.periods.each do | ap |
              if ap.students[initials]
                period = content.periods.find{|pr| pr.id == ap.id }
                course.assignments.push(
                  OpenStruct.new(
                    title: assignment.title, period: period.name, score: ap.students[initials]
                  )
                )
              end
            end
          end
        end
      end
    end

    students.keys.sort.each do | username |
      data = students[username]
      log "#{username} - #{data.name}"
      data.courses.each do | name, cdata |
        period_name = cdata.assignments.group_by{|assignment| assignment.period}.keys.first
        log "    #{name},  Period: #{period_name}"
        cdata.assignments.each do |assignment|
          log "        #{assignment.title} : #{assignment.score}"
        end
      end
    end

  end

end
