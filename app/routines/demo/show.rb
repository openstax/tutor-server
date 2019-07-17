# Loops through the courses and periods that are to be created and worked.
# Logs the student's assignments for review
class Demo::Show < Demo::Base
  lev_routine

  protected

  def exec(config: :all)
    students_hash = {}
    Demo::Config::Course[config].each do |course_config|
      course_config.periods.each do |period|
        (period.students || []).each do |username|
          student = students_hash[username] ||= OpenStruct.new(
            courses: {}, username: username, name: students[username]
          )

          course = student.courses[course_config.course_name] ||= OpenStruct.new(assignments: [])

          course_config.assignments.each do |assignment|
            assignment.periods.each do |ap|
              if ap.students[username]
                period = course_config.periods.find { |pr| pr.id == ap.id }

                course.assignments.push(
                  OpenStruct.new(
                    title: assignment.title, period: period.name, score: ap.students[username]
                  )
                )
              end
            end
          end
        end
      end
    end

    students_hash.keys.sort.each do |username|
      data = students_hash[username]
      log { "#{username} - #{data.name}" }
      data.courses.each do |name, cdata|
        period_name = cdata.assignments.group_by { |assignment| assignment.period }.keys.first
        log { "    #{name},  Period: #{period_name}" }
        cdata.assignments.each do |assignment|
          log { "        #{assignment.title} : #{assignment.score}" }
        end
      end
    end
  end
end
