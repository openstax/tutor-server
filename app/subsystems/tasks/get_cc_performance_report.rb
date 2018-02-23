module Tasks
  class GetCcPerformanceReport
    include PerformanceReportRoutine

    # Overall average score and heading stats do not include dropped student data

    lev_routine express_output: :performance_report

    protected

    def exec(course:, role:)
      raise(SecurityTransgression, 'The caller is not a teacher in this course') \
        unless CourseMembership::IsCourseTeacher[course: course, roles: [role]]

      tz = course.time_zone.try!(:to_tz) || Time.zone
      current_time_ntz = DateTimeUtilities.remove_tz(tz.now)

      taskings = get_cc_taskings(course)
      ecosystems_map = GetCourseEcosystemsMap[course: course]
      cc_tasks_map = get_cc_tasks_map(ecosystems_map, taskings)

      outputs.performance_report = course.periods.reject(&:archived?).map do |period|
        period_cc_tasks_map = cc_tasks_map[period] || {}

        sorted_period_pages =
          period_cc_tasks_map.values                 # ignore the roles keys
                             .flat_map(&:keys)       # ignore the values of page and is_dropped keys
                             .keep_if{|key| key.is_a? Content::Page} # ignore is_dropped
                             .uniq
                             .sort_by(&:book_location)

        # Dropped students are excluded from the CC performance report
        period_students = period.latest_enrollments
                                .joins(:student)
                                .where(student: { dropped_at: nil })
                                .preload(student: {role: {profile: :account}})
                                .map(&:student)

        data_headings = get_cc_data_headings(
          period_cc_tasks_map.values, sorted_period_pages, current_time_ntz
        )

        student_data = period_students.map do |student|
          data = get_student_cc_data(
            period_cc_tasks_map[student.role], sorted_period_pages, tz, current_time_ntz
          )

          {
            name: student.role.name,
            first_name: student.role.first_name,
            last_name: student.role.last_name,
            student_identifier: student.student_identifier,
            role: student.role.id,
            data: data,
            average_score: average_score(
              tasks: data.map { |datum| datum.try!(:[], :task) },
              current_time_ntz: current_time_ntz,
              is_teacher: true
            ),
            is_dropped: false
          }
        end.sort_by do |hash|
          sort_name = "#{hash[:last_name]} #{hash[:first_name]}"
          (sort_name.blank? ? hash[:name] : sort_name).downcase
        end

        Hashie::Mash.new({
          period: period,
          overall_average_score: average(array: student_data.map { |sd| sd[:average_score] }),
          data_headings: data_headings,
          students: student_data
        })
      end
    end

    def get_cc_taskings(course)
      # Return cc tasks for a student, ignoring not_started tasks
      course.taskings.joins(task: :concept_coach_task, role: :student)
                     .where{task.completed_steps_count > 0}
                     .preload(task: {concept_coach_task: :page},
                              role: [{student: {enrollments: :period}}, {profile: :account}])
                     .to_a
    end

    def map_cc_task_to_page(page_to_page_map, cc_task)
      # Map the cc_task page to a new page, but default to the original if the mapping failed
      cc_page = Content::Page.new(strategy: cc_task.page.wrap)
      page_to_page_map[cc_page] || cc_page
    end

    def get_cc_tasks_map(ecosystems_map, taskings)
      pages = taskings.map do |tasking|
        Content::Page.new(strategy: tasking.task.concept_coach_task.page.wrap)
      end
      page_to_page_map = ecosystems_map.map_pages_to_pages(pages: pages)

      taskings.group_by{ |tasking| tasking.role.student.period }
              .each_with_object({}) do |(period, taskings), hash|
        hash[period] = taskings.group_by{ |tasking| tasking.role }
                               .each_with_object({}) do |(role, taskings), hash|
          hash[role] = taskings.group_by do |tasking|
            map_cc_task_to_page(page_to_page_map, tasking.task.concept_coach_task)
          end.each_with_object({}) do |(page, taskings), hash|
            hash[page] = taskings.map{ |tasking| tasking.task.concept_coach_task }
            hash[:is_dropped] = role.student.dropped?
          end
        end
      end
    end

    def get_cc_data_headings(period_cc_tasks_map_array, sorted_period_pages, current_time_ntz)
      # Only include non-dropped students in the heading stats

      sorted_period_pages.map do |page|
        non_dropped_page_tasks =
          period_cc_tasks_map_array.select{|hash| !hash[:is_dropped]}
                                   .flat_map{ |hash| hash[page] }
                                   .compact
                                   .map(&:task)

        {
          cnx_page_id: page.uuid,
          title: "#{page.book_location.join(".")} #{page.title}",
          type: 'concept_coach',
          average_score: average_score(
            tasks: non_dropped_page_tasks, current_time_ntz: current_time_ntz, is_teacher: true
          ),
          average_actual_and_placeholder_exercise_count: average(
            array: non_dropped_page_tasks,
            value_getter: ->(tt) { tt.actual_and_placeholder_exercise_count }
          ),
          completion_rate: completion_fraction(tasks: non_dropped_page_tasks)
        }
      end
    end

    def get_student_cc_data(page_cc_tasks_map_for_role, sorted_pages, tz, current_time_ntz)
      return [nil]*sorted_pages.size if page_cc_tasks_map_for_role.nil?

      tasks = sorted_pages.map do |page|
        cc_tasks = page_cc_tasks_map_for_role[page]
        next if cc_tasks.nil?

        # Only 1 CC task per student per page
        cc_tasks.first.task
      end

      get_task_data(tasks: tasks, tz: tz, current_time_ntz: current_time_ntz, is_teacher: true)
    end
  end
end
