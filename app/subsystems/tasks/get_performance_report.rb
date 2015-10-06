module Tasks
  class GetPerformanceReport
    lev_routine express_output: :performance_report

    protected

    def exec(course:, role:)
      outputs[:performance_report] = \
        if CourseMembership::IsCourseTeacher[course: course, roles: [role]]
          get_performance_report_for_teacher(course)
        else
          raise(SecurityTransgression, 'The caller is not a teacher in this course')
        end
    end

    private

    def get_performance_report_for_teacher(course)
      course.periods.collect do |period|
        taskings = get_taskings(period)
        tasking_plans = sort_tasking_plans(taskings, course, period)
        task_plan_indices = tasking_plans.each_with_index
                                         .each_with_object({}) { |(tasking_plan, index), hash|
                                           hash[tasking_plan.task_plan] = index
                                         }
        role_taskings = taskings.to_a.group_by(&:role)

        sorted_student_data = role_taskings.sort_by { |student_role, _|
                                student_role.profile.account.last_name.downcase
        }

        student_data = sorted_student_data.collect do |student_role, student_taskings|
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

                         {
                           name: student_role.name,
                           first_name: student_role.first_name,
                           last_name: student_role.last_name,
                           role: student_role.id,
                           data: get_student_data(student_tasks)
                         }
                       end

        Hashie::Mash.new({
          period: period,
          data_headings: get_data_headings(tasking_plans, period),
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

    def get_taskings(period)
      task_types = Models::Task.task_types.values_at(:reading, :homework, :external)
      # Return reading, homework and external tasks for a student
      period.taskings.preload(task: {task: {task_plan: {tasking_plans: :target} }},
                              role: {profile: :account})
                     .joins(task: :task)
                     .where(task: {task: {task_type: task_types}})
    end

    def get_data_headings(tasking_plans, period)
      tasking_plans.collect.with_index do |tasking_plan, i|
        task_plan = tasking_plan.task_plan
        {
          title: task_plan.title,
          plan_id: task_plan.id,
          type: task_plan.type,
          due_at: tasking_plan.due_at,
          average: average(task_plan, period)
        }
      end
    end

    def average(task_plan, period)
      # skip if not a homework
      return unless task_plan.type == 'homework'

      # tasks must have more than 0 exercises
      # someone must have started the task or it must be past due
      # tasks must be assigned to students in the given period
      period_tasks = task_plan.tasks.preload(:taskings).select do |task|
        task.exercise_steps_count > 0 && \
        (task.completed_exercise_steps_count > 0 || task.past_due?) && \
        task.taskings.any?{ |tg| tg.course_membership_period_id == period.id }
      end

      # skip if no tasks meet the display requirements
      return if period_tasks.empty?

      period_tasks.map do |task|
        task.correct_exercise_steps_count * 100.0/task.exercise_steps_count
      end.reduce(:+)/period_tasks.size
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

        if task.task_type == 'homework'
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
