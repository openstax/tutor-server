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
      @taskings = {}
      @average = []

      course.periods.collect do |period|
        @average << Hash.new { |h, k| h[k] = [] }
        student_tasks, student_data = [], []
        taskings = get_taskings(period)
        role_taskings = taskings.to_a.group_by{ |tg| tg.role }

        role_taskings.collect do |student_role, taskings|
          student_tasks = taskings.collect{ |tg| tg.task.task }

          student_data << {
            name: student_role.full_name,
            role: student_role.id
          }.merge(get_student_data(student_tasks))
        end

        Hashie::Mash.new({
          period: period,
          data_headings: get_data_headings(student_tasks),
          students: student_data
        })
      end
    end

    def get_taskings(period)
      task_types = Models::Task.task_types.values_at(:reading, :homework, :external)
      # Return reading and homework tasks for a student ordered by due date
      @taskings[period.id] ||= period.taskings
                                     .includes(task: :task, role: {user: {profile: :account}})
                                     .joins(task: :task)
                                     .where(task: {task: {task_type: task_types}})
                                     .order{[role.user.profile.account.full_name, task.task.due_at]}
    end

    def get_data_headings(tasks)
      tasks.collect.with_index { |t, i|
        { title: t.title,
          plan_id: t.tasks_task_plan_id,
          due_at: t.due_at
        }.merge(average(t, i))
      }
    end

    def average(task, index)
      # check if the task is a homework and at least one person has started on it
      return {} unless task.task_type == 'homework' && @average[-1][index].present?
      {
        average: @average[-1][index].reduce(:+) * 100 / @average[-1][index].length
      }
    end

    def get_student_data(tasks)
      {
        data: tasks.collect.with_index { |task, index|
          data = {
            status: task.status,
            type: task.task_type,
            id: task.id,
          }

          if task.task_type == 'homework'
            data.merge!(exercise_count(task, index))
          end

          data
        }
      }
    end

    def exercise_count(task, index)
      exercise_count  = task.exercise_steps_count
      attempted_count = task.completed_exercise_steps_count
      correct_count   = task.correct_exercise_steps_count
      recovered_count = task.recovered_exercise_steps_count

      if attempted_count > 0
        @average[-1][index] << (Float(correct_count) / attempted_count)
      end

      {
        exercise_count: exercise_count,
        correct_exercise_count: correct_count,
        recovered_exercise_count: recovered_count
      }
    end
  end
end
