module Tasks
  class GetPerformanceReport
    lev_routine express_output: :performance_report

    uses_routine GetStudentProfiles,
                 as: :get_student_profiles,
                 translations: { outputs: { type: :verbatim } }

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
      @tasks = {}
      @average = []
      course.periods.collect do |period|
        @average << Hash.new { |h, k| h[k] = [] }
        student_tasks, student_data = [], []
        student_profiles = run(:get_student_profiles, period: period).outputs.profiles
        tasks = get_tasks(student_profiles, period.id)
        exercises = get_exercises(tasks)

        student_profiles.collect do |student_profile|
          student_tasks = tasks.select { |t| taskings_exist?(t, student_profile) }

          student_data << {
            name: student_profile.full_name,
            role: student_profile.entity_role_id
          }.merge(get_student_data(student_tasks, exercises))
        end

        Hashie::Mash.new({
          period: period,
          data_headings: get_data_headings(student_tasks),
          students: student_data
        })
      end
    end

    def get_tasks(student_profiles, period_id)
      role_ids = student_profiles.collect(&:entity_role_id)
      # Return reading and homework tasks for a student ordered by due date
      @tasks[period_id] ||= Models::Task
        .joins { taskings }
        .where { taskings.entity_role_id.in role_ids }
        .where { task_type.in Models::Task.task_types.values_at(:reading, :homework) }
        .order('due_at DESC')
        .includes(:taskings, :task_steps)
    end

    def get_exercises(tasks)
      task_steps = tasks.collect(&:task_steps).flatten
      tasked_exercises = task_steps.select { |ts| ts.tasked_type == 'Tasks::Models::TaskedExercise' }
      tasked_ids = tasked_exercises.collect(&:tasked_id)
      Models::TaskedExercise.where(id: tasked_ids)
    end

    def taskings_exist?(task, profile)
      task.taskings.collect(&:entity_role_id).include?(profile.entity_role_id)
    end

    def get_data_headings(tasks)
      tasks.collect.with_index { |t, i|
        { title: t.title, plan_id: t.tasks_task_plan_id }.merge(average(t, i))
      }
    end

    def average(task, index)
      # check if the task is a homework and at least one person has started on it
      return {} unless task.task_type == 'homework' && @average[-1][index].present?
      {
        average: @average[-1][index].reduce(:+) * 100 / @average[-1][index].length
      }
    end

    def get_student_data(tasks, exercises)
      {
        data: tasks.collect.with_index { |t, i|
          data = {
            status: t.status,
            type: t.task_type,
            id: t.id,
          }

          if t.task_type == 'homework'
            data.merge!(exercise_count(t.task_steps, exercises, i))
          end

          data
        }
      }
    end

    def exercise_count(task_steps, exercises, index)
      tasked_exercises = task_steps.select { |ts| ts.tasked_type == 'Tasks::Models::TaskedExercise' }
      tasked_ids = tasked_exercises.collect(&:tasked_id)
      exercises = exercises.select { |e| tasked_ids.include?(e.id) }

      attempted_count = task_steps.select(&:completed?).length
      correct_count = exercises.select(&:is_correct?).length

      if attempted_count > 0
        @average[-1][index] << (Float(correct_count) / attempted_count)
      end

      {
        exercise_count: exercises.length,
        correct_exercise_count: correct_count,
        recovered_exercise_count: exercises.select(&:can_be_recovered?).length
      }
    end
  end
end
