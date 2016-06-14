module Tasks
  class GetTpPerformanceReport
    include PerformanceReportMethods

    lev_routine express_output: :performance_report

    protected

    def exec(course:)
      taskings = get_taskings(course)

      outputs[:performance_report] = course.periods.map do |period|
        # Sort task_plans by due date
        tasking_plans = sort_tasking_plans(taskings, course, period)

        # Assign column numbers in the performance report to task_plans
        task_plan_col_nums = {}
        tasking_plans.each_with_index do |tasking_plan, col_num|
          task_plan_col_nums[tasking_plan.tasks_task_plan_id] = col_num
        end

        # Sort the students into the performance report rows by name
        role_taskings = taskings.group_by(&:role)
        sorted_student_data = role_taskings.sort_by do |student_role, _|
          sort_name = "#{student_role.last_name} #{student_role.first_name}"
          (sort_name.blank? ? student_role.name : sort_name).downcase
        end

        # This hash will accumulate student tasks to calculate header stats later
        task_plan_results = Hash.new{ |h, key| h[key] = [] }

        student_data = sorted_student_data.map do |student_role, student_taskings|
          # The student scores always show in the student's current period,
          # so skip displaying if they are no longer in this period
          next if student_role.student.period != period

          # Populate the student_tasks array but leave empty spaces (nils)
          # for assignments the student hasn't done
          student_tasks = Array.new(tasking_plans.size)

          student_taskings.each do |tg|
            col_num = task_plan_col_nums[tg.task.tasks_task_plan_id]
            # Skip (leaving the nil in) if task not assigned to current period
            # Could be individual, like practice widget, or assigned to a different period
            next if col_num.nil?

            student_tasks[col_num] = tg.task
          end

          # Gather the student tasks into the task_plan_results hash
          student_tasks.compact.each{ |task| task_plan_results[task.task_plan] << task }

          data = get_student_data(student_tasks)

          {
            name: student_role.name,
            first_name: student_role.first_name,
            last_name: student_role.last_name,
            student_identifier: student_role.student.student_identifier,
            role: student_role.id,
            data: data,
            average_score: average_scores(data.map{ |datum| datum.present? ? datum[:task] : nil })
          }
        end.compact

        Hashie::Mash.new({
          period: period,
          overall_average_score: average(student_data.map{|sd| sd[:average_score]}),
          data_headings: get_data_headings(tasking_plans, task_plan_results),
          students: student_data
        })
      end
    end

    def sort_tasking_plans(taskings, course, period)
      taskings.flat_map do |tg|
        tg.task.task_plan.tasking_plans.select{ |tp| tp.target == period  || tp.target == course }
      end.uniq.sort{ |a, b| [b.due_at_ntz, b.created_at] <=> [a.due_at_ntz, a.created_at] }
    end

    def get_taskings(course)
      task_types = Tasks::Models::Task.task_types.values_at(:reading, :homework, :external)
      # Return reading, homework and external tasks for a student
      # .reorder(nil) removes the ordering from the period default scope so .uniq won't blow up
      # .uniq is necessary for the preloading to work...
      course.taskings
            .joins(task: { task_plan: :tasking_plans })
            .where(task: {task_type: task_types})
            .preload(task: [{task_plan: {tasking_plans: [:target, :time_zone]}}, :time_zone],
                     role: [{student: {enrollments: :period}}, {profile: :account}])
            .reorder(nil).uniq.to_a.select{ |tasking| tasking.task.past_open? }
    end

    def get_data_headings(tasking_plans, task_plan_results)
      tasking_plans.map do |tasking_plan|
        task_plan = tasking_plan.task_plan

        {
          title: task_plan.title,
          plan_id: task_plan.id,
          type: task_plan.type,
          due_at: tasking_plan.due_at,
          average_score: average_scores(task_plan_results[task_plan])
        }
      end
    end
  end
end
