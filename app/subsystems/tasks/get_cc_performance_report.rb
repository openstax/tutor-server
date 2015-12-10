module Tasks
  class GetCcPerformanceReport
    include PerformanceReportMethods

    lev_routine express_output: :performance_report

    protected

    def exec(course:)
      taskings = get_cc_taskings(course)
      ecosystems_map = GetCourseEcosystemsMap[course: course]
      cc_tasks_map = get_cc_tasks_map(ecosystems_map, taskings)

      outputs[:performance_report] = course.periods.collect do |period|
        period_cc_tasks_map = cc_tasks_map[period] || {}
        sorted_period_pages = period_cc_tasks_map
          .values.flat_map(&:keys).uniq.sort{ |a, b| b.book_location <=> a.book_location }

        period_students = period.active_enrollments
                                .preload(student: {role: {profile: :account}})
                                .map(&:student)

        data_headings = get_cc_data_headings(period_cc_tasks_map.values, sorted_period_pages)

        student_data = period_students.collect do |student|
          {
            name: student.role.name,
            first_name: student.role.first_name,
            last_name: student.role.last_name,
            student_identifier: student.student_identifier,
            role: student.role.id,
            data: get_student_cc_data(period_cc_tasks_map[student.role], sorted_period_pages)
          }
        end.sort_by do |hash|
          sort_name = "#{hash[:last_name]} #{hash[:first_name]}"
          (sort_name.blank? ? hash[:name] : sort_name).downcase
        end

        Hashie::Mash.new({
          period: period,
          data_headings: data_headings,
          students: student_data
        })
      end
    end

    def get_cc_taskings(course)
      # Return cc tasks for a student, ignoring not_started tasks
      course.taskings.preload(task: {concept_coach_task: :page},
                              role: [{student: {enrollments: :period}},
                                     {profile: :account}])
                     .joins(task: [:task, :concept_coach_task])
                     .where{task.task.completed_steps_count > 0}
                     .to_a
    end

    def map_cc_task_to_page(page_id_to_page_map, cc_task)
      # Map the cc_task page to a new page, but default to the original if the mapping failed
      page_id_to_page_map[cc_task.page.id] || Content::Page.new(strategy: cc_task.page.wrap)
    end

    def get_cc_tasks_map(ecosystems_map, taskings)
      pages = taskings.map do |tasking|
        Content::Page.new(strategy: tasking.task.concept_coach_task.page.wrap)
      end
      page_id_to_page_map = ecosystems_map.map_pages_to_pages(pages: pages)

      taskings.group_by{ |tasking| tasking.role.student.period }
              .each_with_object({}) do |(period, taskings), hash|
        hash[period] = taskings.group_by{ |tasking| tasking.role }
                               .each_with_object({}) do |(role, taskings), hash|
          hash[role] = taskings.group_by do |tasking|
            map_cc_task_to_page(page_id_to_page_map, tasking.task.concept_coach_task)
          end.each_with_object({}) do |(page, taskings), hash|
            hash[page] = taskings.map{ |tasking| tasking.task.concept_coach_task }
          end
        end
      end
    end

    def get_cc_data_headings(period_cc_tasks_map_array, sorted_period_pages)
      sorted_period_pages.map do |page|
        page_tasks = period_cc_tasks_map_array.flat_map{ |hash| hash[page] }.compact
                                              .map{ |cc_task| cc_task.task.task }

        {
          cnx_page_id: page.uuid,
          title: page.title,
          type: 'concept_coach',
          average: average(page_tasks)
        }
      end
    end

    def get_student_cc_data(page_cc_tasks_map_for_role, sorted_pages)
      return [] if page_cc_tasks_map_for_role.nil?

      tasks = sorted_pages.map do |page|
        cc_tasks = page_cc_tasks_map_for_role[page]
        next if cc_tasks.nil?

        # Here we assume only 1 CC task per student per page
        cc_tasks.first.task.task
      end

      get_student_data(tasks)
    end
  end
end
