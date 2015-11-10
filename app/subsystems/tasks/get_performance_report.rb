module Tasks
  class GetPerformanceReport
    lev_routine express_output: :performance_report

    protected

    def exec(course:, role:)
      outputs[:performance_report] = \
        if CourseMembership::IsCourseTeacher[course: course, roles: [role]]
          course.is_concept_coach ? get_cc_performance_report_for_teacher(course) : \
                                    get_performance_report_for_teacher(course)
        else
          raise(SecurityTransgression, 'The caller is not a teacher in this course')
        end
    end

    private

    def get_performance_report_for_teacher(course)
      taskings = get_taskings(course)
      course.periods.collect do |period|
        tasking_plans = sort_tasking_plans(taskings, course, period)
        task_plan_indices = tasking_plans.each_with_index
                                         .each_with_object({}) { |(tasking_plan, index), hash|
                                           hash[tasking_plan.task_plan] = index
                                         }
        role_taskings = taskings.to_a.group_by(&:role)
        sorted_student_data = role_taskings.sort_by { |student_role, _|
                                student_role.profile.account.last_name.downcase
        }
        task_plan_results = Hash.new{|h, key|h[key] = []}

        student_data = sorted_student_data.collect do |student_role, student_taskings|
                         # skip if student is no longer in the current period
                         next if student_role.student.period != period

                         # Populate the student_tasks array but leave empty spaces (nils)
                         # for assignments the student hasn't done
                         student_tasks = Array.new(tasking_plans.size)
                         student_taskings.each do |tg|
                           index = task_plan_indices[tg.task.task.task_plan]
                           # skip if task not assigned to current period
                           # could be individual, like practice widget,
                           # or assigned to a different period
                           next if index.nil?
                           student_tasks[index] = tg.task.task
                         end

                         # gather the task into the results for use in calculating header stats
                         student_tasks.each do | task |
                           next unless task
                           task_plan_results[task.task_plan] << task
                         end

                         {
                           name: student_role.name,
                           first_name: student_role.first_name,
                           last_name: student_role.last_name,
                           student_identifier: student_role.student.student_identifier,
                           role: student_role.id,
                           data: get_student_data(student_tasks)
                         }
                       end.compact

        Hashie::Mash.new({
          period: period,
          data_headings: get_data_headings(tasking_plans, task_plan_results),
          students: student_data
        })
      end
    end

    def sort_tasking_plans(taskings, course, period)
      taskings.flat_map { |tg|
        tg.task.task.task_plan.tasking_plans.select do |tp|
          tp.target == period  || tp.target == course
        end
      }.uniq.sort { |a, b|
        [b.due_at, b.created_at] <=> [a.due_at, a.created_at]
      }
    end

    def get_taskings(course)
      task_types = Models::Task.task_types.values_at(:reading, :homework, :external)
      # Return reading, homework and external tasks for a student
      course.taskings.preload(task: {task: {task_plan: {tasking_plans: :target} }},
                              role: [{student: {enrollments: :period}},
                                     {profile: :account}])
                     .joins(task: :task)
                     .where(task: {task: {task_type: task_types}})
    end

    def get_data_headings(tasking_plans, task_plan_results)
      tasking_plans.map do |tasking_plan|
        task_plan = tasking_plan.task_plan
        {
          title: task_plan.title,
          plan_id: task_plan.id,
          type: task_plan.type,
          due_at: tasking_plan.due_at,
          average: average(task_plan, task_plan_results[task_plan])
        }
      end
    end

    # returns the average for the task_plan
    def average(task_plan, tasks)
      # skip if not a homework.
      return unless task_plan.type == 'homework'

      # tasks must have more than 0 exercises and
      # have been started or it must be past due
      valid_tasks = tasks.select do |task|
        task.exercise_steps_count > 0 && \
        (task.completed_exercise_steps_count > 0 || task.past_due?)
      end

      # skip if no tasks meet the display requirements
      return if valid_tasks.none?

      valid_tasks.reduce(0){ |sum, task|
        sum + ( task.correct_exercise_steps_count * 100.0 / task.exercise_steps_count )
      } / valid_tasks.size
    end

    def get_cc_performance_report_for_teacher(course)
      taskings = get_cc_taskings(course)
      cc_tasks_map = get_cc_tasks_map(taskings)

      course.periods.collect do |period|
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
        end.sort_by{ |hash| [hash[:last_name].downcase, hash[:first_name].downcase] }

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

    def get_cc_tasks_map(taskings)
      taskings.group_by{ |tasking| tasking.role.student.period }
              .each_with_object({}) do |(period, taskings), hash|
        hash[period] = taskings.group_by{ |tasking| tasking.role }
                               .each_with_object({}) do |(role, taskings), hash|
          hash[role] = taskings.group_by{ |tasking| tasking.task.concept_coach_task.page }
                               .each_with_object({}) do |(page, taskings), hash|
            hash[page] = taskings.map{ |tasking| tasking.task.concept_coach_task }
          end
        end
      end
    end

    def get_cc_data_headings(period_cc_tasks_map_array, sorted_period_pages)
      sorted_period_pages.map do |page|
        page_cc_tasks = period_cc_tasks_map_array.flat_map{ |hash| hash[page] }

        {
          title: page.title,
          type: 'concept_coach',
          average: cc_average(page_cc_tasks)
        }
      end
    end

    # returns the average for the page
    def cc_average(page_cc_tasks)
      page_tasks = page_cc_tasks.compact.map{ |cc_task| cc_task.task.task }
      correct_count = page_tasks.map(&:correct_exercise_count).reduce(:+)
      completed_count = page_tasks.map(&:completed_exercise_count).reduce(:+)
      correct_count * 100.0/completed_count
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

    def get_student_data(tasks)
      tasks.collect do |task|
        # skip if the student hasn't worked this particular task_plan
        next if task.nil?

        data = {
          late: task.late?,
          status: task.status,
          type: task.task_type,
          id: task.id,
          due_at: task.due_at,
          last_worked_at: task.last_worked_at
        }

        if task.task_type == 'homework' || task.task_type == 'concept_coach'
          data.merge!(exercise_counts(task))
        end

        data
      end
    end

    def exercise_counts(task)
      exercise_count  = task.actual_and_placeholder_exercise_count
      correct_count   = task.correct_exercise_steps_count
      recovered_count = task.recovered_exercise_steps_count

      {
        actual_and_placeholder_exercise_count: exercise_count,
        correct_exercise_count: correct_count,
        recovered_exercise_count: recovered_count
      }
    end
  end
end
